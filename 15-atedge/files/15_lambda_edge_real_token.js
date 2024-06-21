'use strict';
const AWS = require('aws-sdk');
const jwt = require('jsonwebtoken');
const cookie = require('cookie');
const jwksClient = require('jwks-rsa');
const jose = require('node-jose');
const querystring = require('querystring');
const url = require('url');
const ssm = new AWS.SSM({ region: 'us-east-1' });
const AUTH_COOKIE_NAME = "accessToken";

const loadParameter = async(key, withDecryption = false) => {
    const { Parameter } = await ssm.getParameter({ Name: key, WithDecryption: withDecryption }).promise();
    return Parameter.Value;
};

async function getDecodedJwt(requestHeaders, client) {
    if (requestHeaders.cookie) {
        console.debug(`Found $${requestHeaders.cookie.length} Cookie headers`);

        for (let i = 0; i < requestHeaders.cookie.length; ++i) {
            const cookies = cookie.parse(requestHeaders.cookie[i].value);

            if (AUTH_COOKIE_NAME in cookies) {
                console.debug(`Auth cookie found at Cookie header index $${i}`);

                const signedJwt = cookies[AUTH_COOKIE_NAME];

                try {
                    const decodedJwt = await verifyAccessToken(signedJwt, client);
                    console.debug(`JWT verified, expires at $${decodedJwt.exp}`);
                    return decodedJwt;
                } catch (err) {
                    console.warn(`JWT verification error: $${err.message}`);
                }
            } else {
                console.debug(`Auth cookie not found at Cookie header index $${i}`);
            }
        }
    } else {
        console.debug('No Cookie headers in request');
    }

    return null;
}

async function verifyAccessToken(accessToken, client) {
    /*
    * Verify the access token with your Identity Provider here (check if your
    * Identity Provider provides an SDK).
    *
    * This example assumes this method returns a Promise that resolves to
    * the decoded token, you may need to modify your code according to how
    * your token is verified and what your Identity Provider returns.
    * 
    * Fetch the KID attribute from your JWKS Endpoint to verify its integrity
    * You can either use a Environment Variable containing the KID or call AWS Secrets Manager with KID already securely stored.
    */

    // get the kid from the headers prior to verification
    let header = jose.util.base64url.decode(accessToken.split('.')[0]);
    let jwks = JSON.parse(header);
    let kid = jwks.kid;
    console.log('kid: ', kid);        

    const key = await client.getSigningKey(kid);
    const signingKey = key.getPublicKey();
    const decoded = jwt.verify(accessToken, signingKey);
    console.log('decoded: ', decoded);
    // additionally we can verify the token expiration
    //var current_ts = Math.floor(new Date() / 1000);
    //if (current_ts > decoded.claims.exp) {
    //    throw new Error('Unauthorized: Token is expired');
    //}

    return decoded
};

exports.handler = async(event, context, callback) => {
    
    console.log('event:', JSON.stringify(event));

    const request = event.Records[0].cf.request;
    const headers = request.headers;
    const queryParams = querystring.parse(request.querystring);
    const frontHostHeader = headers.host[0].value;

    console.log(`frontHostHeader: ${frontHostHeader}`);

    // Supprimer le préfixe 'front-'
    const hostHeader = frontHostHeader.replace(/^front-/, '');

    console.log(`hostHeader: ${hostHeader}`);

    //const COGNITO_DOMAIN = "kaiac.auth.us-west-2.amazoncognito.com";
    //const CLIENT_ID = "2e47n0ef09161gupgk1t3209pl";
    const COGNITO_DOMAIN = await loadParameter('COGNITO_DOMAIN');
    console.log(`COGNITO_DOMAIN: ${COGNITO_DOMAIN}`);
    const CLIENT_ID = await loadParameter('CLIENT_ID');
    console.log(`CLIENT_ID: ${CLIENT_ID}`);
    const JWKS_ENDPOINT = await loadParameter('JWKS_ENDPOINT');
    console.log(`JWKS_ENDPOINT: ${JWKS_ENDPOINT}`);


    console.log('queryParams:', JSON.stringify(queryParams));
    // Vérifiez la présence du token OAuth2 dans les en-têtes
    //if (!headers.authorization || !headers.authorization[0].value.startsWith('Bearer ')) {

    const LOGIN_URL = `https://${COGNITO_DOMAIN}/login?response_type=token&client_id=${CLIENT_ID}&redirect_uri=https://${hostHeader}/login`;

    const client = jwksClient({ jwksUri: JWKS_ENDPOINT });

    const verifiedJwt = await getDecodedJwt(headers, client);

    console.log(verifiedJwt);

    if (verifiedJwt !== null) {
        // TODO: refresh token if it expires soon
        // TODO: revoke JWT if token was revoked before end of the TTL
        console.info('Authenticated, forwarding request');
        callback(null, request);
    } else {
        
        // Accéder à l'URI
        const uri = request.uri;
        
        console.log('Original URI:', uri);

        if (uri.includes('#')) {

            const fragment = uri.split('#')[1];
            // Extraire les paramètres du fragment
            const params = new URLSearchParams(fragment);
            const access_token = params.get('access_token');
            const id_token = params.get('id_token');
            
            var token = null;
            if(access_token){
                token = access_token;
            }

            if(id_token){
                token = id_token;
            }
            
            console.log('Access Token:', token);
            
            console.info('Login successful');
            
            // Ajoutez le token OAuth2 en tant que cookie
            headers['set-cookie'] = [{
                key: 'Set-Cookie',
                value: `${AUTH_COOKIE_NAME}=${token}; Path=/; Secure; HttpOnly;`
            }];

            callback(null, request);

        } else {
            console.info('No access token supplied, forwarding to login page');

            const response = {
                status: '302',
                statusDescription: 'Found',
                headers: {
                    'location': [{
                        key: 'Location',
                        value: LOGIN_URL
                    }],
                    'cache-control': [
                        {
                            key: 'Cache-Control',
                            value: 'private'
                        }
                    ]
                }
            };
            
            callback(null, response);
        }
    }

};
