angular.module('transaction').
controller('DeclareCtrl', ($scope, $state, login, userList, Announce, Transaction)->
  $scope.transaction  = {}
  $scope.userList     = []
  demandList          = []
  proposalList        = []
  $scope.announceList = []

  ########### Edit
  if $state.$current.locals.globals.transaction
    transaction         = $state.$current.locals.globals.transaction
    $scope.transaction  = transaction

    transaction.reason = {
      text:     transaction.message
      announce: transaction.reference
    }
    delete transaction.message
    delete transaction.reference

    if transaction.to != login.getName() and login.proxys.indexOf(transaction.to) == -1
      transaction.toField = transaction.to
      transaction.to      = 'another'

    if transaction.from != login.getName() and login.proxys.indexOf(transaction.from) == -1
      transaction.fromField = transaction.from
      transaction.from      = 'another'


  $scope.newTransactionSubmit = ->
    transaction = angular.copy($scope.transaction)

    if transaction.to == 'another'
      transaction.to = transaction.toField
    if transaction.from == 'another'
      transaction.from = transaction.fromField
    delete transaction.toField
    delete transaction.fromField
    transaction.update = 'create'

    Transaction.update(transaction).then(
      (data)-> #Success
        $state.go('home')
      ,(err)-> #Error
        console.log err
    )

  $scope.$watch('transaction.from', (value)->
    if value != login.getName()
      $scope.transaction.to = ''
  )

  $scope.$watchCollection('[transaction.fromField, transaction.from]', (value)->
    if value[1] == 'another'
      search = value[0]
    else
      search = value[1]

    if not search?
      search = ""

    Announce.view({
      view: 'demand_all'
      key:  search
    }).then(
      (data)-> #Success
        demandList          = data
        $scope.announceList = proposalList.concat(data)
      ,(err)-> #Error
        console.log err
    )
  )

  $scope.$watchCollection('[transaction.toField, transaction.to]', (value)->
    if value[1] == 'another'
      search = value[0]
    else
      search = value[1]

    if not search?
      search = ""

    Announce.view({
      view: 'proposal_all'
      key:   search
    }).then(
      (data) -> #Success
        proposalList        = data
        $scope.announceList = demandList.concat(data)
      ,(err) -> #Error
        console.log err
    )
  )

  updateUserList = ->
    $scope.userList = []
    for user in userList
      if user.name != login.getName()
        $scope.userList.push(user.name)

  updateUserList()
  $scope.$on('SessionChanged', updateUserList)
)