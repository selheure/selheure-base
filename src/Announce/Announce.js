angular.module('announce').
factory('Announce', function(CouchDB, db){
  return CouchDB(db.url, db.name, 'announce')
});
