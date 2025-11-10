classdef instance
    % A Knapsack Instance with normalized values and weights (C=1)
    % Input:
    %   Generator: the generator you wish to use
    %   nItems(optional) : how many items the instance will have
    % Properties:
    %   nItems      : number of items in the instance
    %   values      : values of the items
    %   weights     : weights of the items
    %   ratio       : value/weight ratio of the items
    %                   The items are sorted in descending order based on their ratio
    %   timePeriod  : how many actions have already been taken
    %   totalVal    : the total value of items previously selected
    properties
        nItems
        values
        weights
        ratio
        timePeriod
        totalVal
        originalIndex
        binaryKP
        bannedPatterns %banned patterns have to be maximal patterns
    end

    methods
        function obj = instance(options)
            arguments
                options.generator = [];
                options.nItems = 20;
                options.v = [];
                options.w = [];
                options.binaryKP = true;
                options.bannedPatterns=[];
            end
            % if nargin == 1
            %     obj.nItems = 20;
            % else
            %     obj.nItems = varargin{1};
            % end
            if numel(options.v) == 0 %if no v vector given, generate v and w
                obj.nItems = options.nItems;
                generator = options.generator;
                [obj.values, obj.weights] = generator(obj.nItems);
            else %v and w given
                obj.values = options.v;
                obj.weights= options.w;
                obj.nItems = numel(obj.values);
            end
            if numel(options.bannedPatterns) == 0
                obj.bannedPatterns = [];
            else
                obj.bannedPatterns = options.bannedPatterns;
            end
            %some post processing
            obj.originalIndex = 1:obj.nItems;
            infeasibleItems = obj.weights >1;
            obj.weights(infeasibleItems) = [];
            obj.values(infeasibleItems)  = [];
            obj.nItems = obj.nItems - sum(infeasibleItems);
            obj.values = obj.values./(max(obj.values));
            obj.ratio = obj.values./obj.weights;
            [obj.ratio, indices] = sort(obj.ratio, 'descend');
            obj.values = obj.values(indices);
            obj.weights= obj.weights(indices);
            obj.originalIndex = obj.originalIndex(indices); %=indices
            obj.timePeriod = 1;
            obj.totalVal   = 0;
            obj.binaryKP = options.binaryKP;
        end

        function obj = selectItem(obj, item, options)
            arguments
                obj
                item
                options.currentSol = [];
            end
            %Selects an item from the instance, removes infeasible items,
            %and normalizes the instance (C=1)
            obj.totalVal = obj.totalVal + obj.values(item);
            newWeights = round(obj.weights/(1-obj.weights(item)),14); %floating point errors :(
            infeasibleItems = newWeights>1;
            if obj.binaryKP
                infeasibleItems(item) = 1;
            end
            if numel(obj.bannedPatterns) ~= 0
                nearPatterns = find((sum(obj.bannedPatterns,2) - sum(obj.bannedPatterns(:,[options.currentSol, obj.originalIndex(item)]),2))==1);%index of the patterns that are one item from completion
                bannedItems = [];
                if numel(nearPatterns)>0
                for pattern = nearPatterns'
                    currentBannedPattern = obj.bannedPatterns(pattern,:);
                    currentBannedPattern([options.currentSol, obj.originalIndex(item)]) = 0;
                    bannedItem = find(currentBannedPattern);
                    bannedItems = [bannedItems, find(obj.originalIndex==bannedItem)];%#ok
                end
                infeasibleItems(bannedItems) = 1;
                end
            end
            obj.values(infeasibleItems)=[];
            obj.weights = newWeights;
            obj.weights(infeasibleItems)=[];
            obj.ratio(infeasibleItems) = []; %We don't calculate new ratios
            obj.originalIndex(infeasibleItems) = [];
            obj.nItems = obj.nItems - sum(infeasibleItems);
            obj.timePeriod = obj.timePeriod +1;
        end

        function varargout = greedySolve(obj)
            indexSol = [];
            dummyObj = obj;
            while dummyObj.nItems>0
                if dummyObj.values(1)<0 %Shouldn't happen, but can happen with shadowprices
                    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=1;
                    break
                end
                newItem = dummyObj.originalIndex(1);
                dummyObj = dummyObj.selectItem(1,'currentSol',indexSol);
                indexSol = [indexSol, newItem]; %#ok add index of first item
            end
            varargout{1} = dummyObj.totalVal;
            if nargout >= 2
                varargout{2} = indexSol;
            end
        end


        function varargout = BPsolve(obj)
            options = optimoptions('intlinprog','Display','off');
            lowerBound = zeros(1,obj.nItems);
            if obj.binaryKP
                upperBound = ones(1,obj.nItems);
            else
                upperBound = ceil(1./obj.weights);
            end
            [sol] = intlinprog(-obj.values, 1:obj.nItems, obj.weights, 1,[],[],lowerBound, upperBound,[],options);
            
            varargout{1} = sum(obj.values.*round(sol')); %more precise than taking the objective of the ILP???
            if nargout >= 2
                varargout{2} = obj.originalIndex(find(round(sol')));
            end
        end

        function varargout = GurobiSolve(obj, nonExact, objBound, mipGap, warmStart)
            arguments
                obj
                nonExact = false;
                objBound = inf;  %gurobi default
                mipGap   = 0;
                warmStart= [];
            end
            model.A = sparse(obj.weights);
            model.obj = obj.values;
            model.rhs = 1;
            model.sense = '<';
            model.modelsense = 'max';
            model.vtype = 'B';
            model.ub = ones(1,obj.nItems);
            params.outputflag = 0;
            if nonExact
                if mipGap %a gap is given, otherwise use default
                    params.MIPGap = mipGap;
                end
                params.BestObjStop = objBound;
            end
            if ~isempty(warmStart)
                model.start = double(ismember(obj.originalIndex, warmStart)); %revert to index in s
            end
            results = gurobi(model, params);
            varargout{1} = results.objval;
            if nargout >= 2
                varargout{2} = obj.originalIndex(find(round(results.x)));
            end
            if nargout >= 3
                varargout{3} = results.mipgap;
            end
            if nargout >= 4
                varargout{4} = results.x;
            end
        end
    end
end
