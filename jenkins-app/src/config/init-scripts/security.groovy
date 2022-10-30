#!groovy
import hudson.security.*
import jenkins.model.*
import jenkins.security.s2m.AdminWhitelistRule

// Set super admin account

def env = System.getenv()
def instance = Jenkins.getInstance()
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
def username = env['JENKINS_ADMIN_USERNAME']
def password = env['JENKINS_ADMIN_PASSWORD']

hudsonRealm.createAccount(username, password)
instance.setSecurityRealm(hudsonRealm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
instance.setAuthorizationStrategy(strategy)
instance.save()