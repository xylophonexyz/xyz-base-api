if Rails.env.test? || Rails.env.development?
  @oauth_app = Doorkeeper::Application.new(name: 'xyz-dev', redirect_uri: 'http://localhost:8080/callback/email')
  @oauth_app.save
  p 'oauth app created'
  p 'app uid: ' + @oauth_app.uid
  p 'app secret: ' + @oauth_app.secret

  @oauth_app = Doorkeeper::Application.new(name: 'xyz-dev-ui', redirect_uri: 'http://localhost:4200/callback/email')
  @oauth_app.save
  p 'oauth app created'
  p 'app uid: ' + @oauth_app.uid
  p 'app secret: ' + @oauth_app.secret
end
