angular.module('selheure').
config(function($stateProvider, $urlRouterProvider){
  $stateProvider.
    state('home', {
      url:         '/',
      templateUrl: 'partials/home.html',
      controller:  'HomeCtrl',
      resolve: {
        announces: function(Announce) {
          return Announce.all({
            limit: 10,
          });
        },
      }
    }).
    state('echange.new', {
      url:         '/echanges/nouvelle',
      templateUrl: 'partials/transactions_new.html',
      controller:  'NewTransactionCtrl',
    }).
    state('work', {
      url:         '/travail_collectif',
      templateUrl: 'partials/collective_work.html',
      controller:  'CollectiveWorkCtrl',
    });

    $urlRouterProvider.otherwise('/');
});
