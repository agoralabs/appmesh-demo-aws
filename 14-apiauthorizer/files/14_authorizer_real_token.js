    const util = require('util');
    const jwt = require('jsonwebtoken');
    const jwksClient = require('jwks-rsa');
    const https = require('https');
    const jose = require('node-jose');

    // Configure the JWKS URI endppoint from your OIDC provider 
    const client = jwksClient({ jwksUri: process.env.JWKS_ENDPOINT });
    let jwks, kid;
    const allowedHosts = process.env.ALLOWED_HOSTS;
    const allowedHostsArray = allowedHosts.split(',');

    // Help function to verify the accessToken
    async function verifyAccessToken(accessToken) {
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
        jwks = JSON.parse(header);
        kid = jwks.kid;
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

    // https://github.com/aws-samples/openbanking-brazilian-auth-samples/blob/main/resources/lambda/lambda-auth.js#L33
    exports.handler = async (event, context, callback) => {

        console.log(event);
        var host = event.headers.host;
        console.log(`Received host: ${host}`);
        var routeArn = event.routeArn;
        console.log(`Received routeArn: ${routeArn}`);
        console.log(`Allowed hosts: ${allowedHostsArray}`);
  
        // Declare Policy
        let iamPolicy = null;
        
        if (!allowedHostsArray.includes(host)) {
            

            //const token = event.authorizationToken.replace('Bearer ', '');
            const bearer = event.headers.authorization;
            console.log('Bearer: ', bearer);
            
            const token = bearer.replace('Bearer ', '');
            console.log('JWT Token: ', token);
        
            if (token == undefined || token.toString().trim().length == 0) {
                throw new Error('Unauthorized, Authorization token not found');
            }
        

            await verifyAccessToken(token).then(data => {
                // Retrieve token scopes
                console.log('Decoded and Verified JWT Token', JSON.stringify(data))
                // For testing purposes using a ID token without scopes. If you have an access token with scopes, 
                // uncomment 'data.claims.scp' and pass the array of scopes present in the scp attribute instead.
                //const scopeClaims = ['email']// data.claims.scp;
                // Generate IAM Policy
                iamPolicy = generatePolicy('user', 'Allow', routeArn);
            })
                .catch(err => {
                    console.log(err);
                    iamPolicy = generatePolicy('user', 'Deny', routeArn);
                });
            console.log('IAM Policy', JSON.stringify(iamPolicy));

            callback(null, iamPolicy);

          
        }else{

          callback(null, generatePolicy('user', 'Allow', routeArn));
        }
        
  
    };
        

    // Help function to generate an IAM policy
    var generatePolicy = function(principalId, effect, resource) {
        var authResponse = {};
        
        authResponse.principalId = principalId;
        if (effect && resource) {
            var policyDocument = {};
            policyDocument.Version = '2012-10-17'; 
            policyDocument.Statement = [];
            var statementOne = {};
            statementOne.Action = 'execute-api:Invoke'; 
            statementOne.Effect = effect;
            statementOne.Resource = resource;
            policyDocument.Statement[0] = statementOne;
            authResponse.policyDocument = policyDocument;
            console.log(resource);
            console.log(statementOne);
            console.log(policyDocument);
        }
        
        // Optional output with custom properties of the String, Number or Boolean type.
        authResponse.context = {
            "stringKey": "stringval",
            "numberKey": 123,
            "booleanKey": true
        };
        console.log(authResponse);
        return authResponse;
    }