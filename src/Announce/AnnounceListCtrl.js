angular.module('announce').
controller('AnnounceListCtrl', function($scope, announces, config) {
  $scope.announces     = announces;
  $scope.announceTypes = config.announceTypes;
  $scope.categories    = config.categories;
  $scope.subCategories = config.sub_categories;
  console.log(config);
});
