ENV_APP_GL_AWS_REGION="us-west-2"
ENV_APP_GL_AWS_CRED_FILE_PATH="~/.aws/credentials"
ENV_APP_GL_AWS_CRED_PROFILE="default"
ENV_APP_GL_KAIAC_MODULE="fedclient"
ENV_APP_GL_NAMESPACE="k8s"
ENV_APP_GL_NAME="mesh"
ENV_APP_GL_STAGE="spa"
ENV_APP_GL_USER_POOL_NAME="keycloak-user-pool"
ENV_APP_GL_USER_POOL_PROVIDER_NAME="keycloak"
ENV_APP_GL_USER_POOL_APP_CLIENT_NAME="angularspa"
ENV_APP_GL_USER_POOL_APP_CLIENT_CALLBACK_URLS="https://service-spa.skyscaledev.com/login"
ENV_APP_GL_USER_POOL_APP_CLIENT_LOGOUT_URLS="https://keycloak-demo1-prod.skyscaledev.com/realms/rcognito/protocol/openid-connect/logout"
ENV_APP_GL_USER_POOL_OAUTH_FLOWS="implicit, code"
ENV_APP_GL_USER_POOL_OAUTH_SCOPES="openid, email, profile"
ENV_APP_GL_USER_POOL_OAUTH_CUSTOM_SCOPES=""
ENV_APP_GL_USER_POOL_OAUTH_REFRESH_TOKEN_VALIDIY="8"
ENV_APP_GL_USER_POOL_OAUTH_ACCESS_TOKEN_VALIDIY="480"
ENV_APP_GL_USER_POOL_OAUTH_ID_TOKEN_VALIDIY="480"