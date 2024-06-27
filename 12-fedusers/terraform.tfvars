ENV_APP_GL_AWS_REGION="us-west-2"
ENV_APP_GL_AWS_CRED_FILE_PATH="~/.aws/credentials"
ENV_APP_GL_AWS_CRED_PROFILE="default"
ENV_APP_GL_KAIAC_MODULE="fedusers"
ENV_APP_GL_NAMESPACE="k8s"
ENV_APP_GL_NAME="mesh"
ENV_APP_GL_STAGE="cognito"
ENV_APP_GL_COGNITO_DOMAIN_NAME="kaiac"
ENV_APP_GL_USER_POOL_NAME="keycloak-user-pool"
ENV_APP_GL_USER_POOL_PROVIDER_TYPE="OIDC"
ENV_APP_GL_USER_POOL_PROVIDER_NAME="keycloak"
ENV_APP_GL_USER_POOL_PROVIDER_CLIENT_ID="rcognitoclient"
ENV_APP_GL_USER_POOL_PROVIDER_CLIENT_SECRET_SCRIPT="/vagrant/kaiac/kvbooks/appmesh/12_client_secret.sh"
ENV_APP_GL_USER_POOL_ATT_REQ_METHOD="POST"
ENV_APP_GL_USER_POOL_ISSUER_URL="https://keycloak-demo1-prod.skyscaledev.com/realms/rcognito"
ENV_APP_GL_USER_POOL_USERNAME_ATTRIBUTES="username, email, phone_number"
ENV_APP_GL_USER_POOL_AUTHORIZE_SCOPES="openid profile email"
ENV_APP_GL_USER_POOL_ATTRIBUTE_MAPPING_JSON="/vagrant/kaiac/kvbooks/appmesh/12_fedusrpool_att_map.json"