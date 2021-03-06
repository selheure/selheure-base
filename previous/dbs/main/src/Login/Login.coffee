angular.module('login').
factory('login', ($q, $rootScope, $timeout, $http, User, db) ->
  login = {
    proxys: []
    currentUser: {
      name:     ''
      password: ''
      roles:    []
    }

    getPassword: ->
      if this.isConnected()
        return this.currentUser.password
      else
        return ''

    getName: (name) ->
      if not name?
        if this.isConnected()
          name = this.currentUser.name
        else
          return ''
      name = User.getName(name)
      if this.isConnected()
        this.currentUser.name = name
      return name

    getFullyQualifiedName: (name) ->
      return User.getId(name)

    _lowLevelSignIn: (username, password) ->
      userId = User.getId(username)
      $http.post("/_session", {
        name:     userId
        password: password
      })

    signIn: (username, password) ->
      defer = $q.defer()
      @_lowLevelSignIn(username, password).then(
        (data)=> #Success
          data = data.data
          data['password'] = password
          @currentUser      = data
          $rootScope.$broadcast('SignIn', @getName() )
          $rootScope.$broadcast('SessionChanged', @getName())
          defer.resolve(data)
        ,(err)-> #Error
          defer.reject(err)
      )

      return defer.promise

    signUp: (user) ->
      defer = $q.defer()
      userData = {}
      userData[db.main.name] =
        name:           user.name
        email:          user.email
        tel:            user.tel
        localization:   user.localization
      fullName = @getFullyQualifiedName(user.name)
      # Create the user inside _users db
      $http.post('/_users/',{
        _id:       "org.couchdb.user:#{fullName}"
        name:      fullName
        type:      "user"
        roles:     []
        password:  user.password
        data:      userData
      }).then(
        (data)=> #Success
          @signIn(user.name, user.password).then(
            (data) -> #Success
              defer.resolve(data)
            ,(err) -> #Error
              defer.reject(err)
          )
        ,(err)-> #Error
          defer.reject(err)
      )
      return defer.promise

    signOut: ->
      defer = $q.defer()
      $http.delete('/_session').then(
        (data) => #Success
          data = data.data
          @currentUser = {
            name:     data.name
            password: ''
            roles:     data.roles
          }
          $rootScope.$broadcast('SignOut')
          $rootScope.$broadcast('SessionChanged', @getName())
          defer.resolve(data)
        ,(err) => #Error
          defer.reject(err)
      )

      return defer.promise

    getInfo: ->
      defer = $q.defer()
      $http.get('/_session').then(
        (data) => #Success
          data = data.data.userCtx
          @currentUser = data
          $timeout( =>
            $rootScope.$broadcast('SessionStart', @getName())
            $rootScope.$broadcast('SessionChanged', @getName())
            if @isConnected()
              $rootScope.$broadcast('SignIn', @getName())
            else
              $rootScope.$broadcast('SignOut')
          , 100)
          defer.resolve(data)
        ,(err) => #Error
          defer.reject(err)
      )

      return defer.promise

    isConnected: ->
      return this.currentUser.name? and this.currentUser.name != ''

    isValidated: ->
      return @hasRole(db.main.name)

    isAppAdmin: ->
      return @hasRole(db.main.name + "_admin")

    hasRole: (role) ->
      for piece in this.currentUser.roles || []
        if role == piece or piece == 'admin'
          return true
          break
      return false

    isAuthorized: (name)->
      return @getName() == name or @proxys.indexOf(name) > -1

    _updateUserDoc: (username, editUserDocCallback)->
      fqName = @getFullyQualifiedName(username)
      userDbId = "/_users/org.couchdb.user:#{fqName}"
      $http.get(userDbId).then (resp) =>
        $http.put(
          userDbId
          editUserDocCallback(resp.data)
        )


    updateUserData: (username, newData)->
      @_updateUserDoc(
        username
        (userDoc) =>
          # set/modify user data for this app (userDoc.data.<mainDbName>)
          if not userDoc.data[db.main.name]
            userDoc.data[db.main.name] = {}
          for element,value of newData
            if value?
              userDoc.data[db.main.name][element] = value
          return userDoc
      )

    changePwd: (username, oldPwd, newPwd)->
      @_lowLevelSignIn(username, oldPwd).then(
        (result) =>
          @_updateUserDoc(
            username
            (userDoc) =>
              userDoc.password = newPwd
              return userDoc
          ).then () =>
            # sign in again because session has been destroyed
            @_lowLevelSignIn(username, newPwd)
        , (err) =>
          return 'CHPWD_BADOLDPWD'
      )
  }

  $rootScope.$on('$routeChangeSuccess', ->
    $timeout( ->
      $rootScope.$broadcast('SessionChanged', login.getName())
      if login.isConnected()
        $rootScope.$broadcast('SignIn', login.getName())
      else
        $rootScope.$broadcast('SignOut', login.getName())
    ,200)
  )

  $rootScope.$on('SessionChanged', ($event, name)->
    if name == ''
      login.proxys = []
    else
      userNamePrefix = User.getId('')
      for role in login.currentUser.roles
        if role.indexOf(userNamePrefix) == 0 and
        login.proxys.indexOf(role) == -1
          login.proxys.push(User.getName(role))
  )

  return login
)
