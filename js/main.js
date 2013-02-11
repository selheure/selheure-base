angular.module('directive', []).directive('contenteditable', function() {
    return {
        require: 'ngModel',
        link: function(scope, elm, attrs, ctrl) {
            // view -> model
            elm.bind('keydown', function() {
                scope.$apply(function() {
                    ctrl.$setViewValue(elm.html());
                });
            });
            // model -> view
            ctrl.$render = function(value) {
                elm.html(value);
            };
            // load init value from DOM
            ctrl.$setViewValue(elm.html());
        }
    };
});


/*function Cntl($scope) {
    $scope.updateBudgets = function(b, b_total) {
        $scope.budget_finance;
    }
*/
