import {
  CognitoUserPool,
  CognitoUser,
  AuthenticationDetails,
} from "amazon-cognito-identity-js";

const userPool = new CognitoUserPool({
  UserPoolId: import.meta.env.VITE_COGNITO_USER_POOL_ID,
  ClientId: import.meta.env.VITE_COGNITO_CLIENT_ID,
});

/**
 * Connecte un utilisateur (USER_PASSWORD_AUTH) et renvoie son idToken JWT.
 * L'idToken est utilisé comme Bearer token vers l'API Gateway.
 */
export function signIn(email, password) {
  return new Promise((resolve, reject) => {
    const user = new CognitoUser({ Username: email, Pool: userPool });
    const details = new AuthenticationDetails({
      Username: email,
      Password: password,
    });

    user.authenticateUser(details, {
      onSuccess: (session) => resolve(session.getIdToken().getJwtToken()),
      onFailure: (err) => reject(err),
      // Cas d'un mot de passe temporaire à changer au premier login
      newPasswordRequired: () =>
        reject(new Error("Mot de passe à réinitialiser via la console Cognito.")),
    });
  });
}

/** Récupère l'idToken de la session courante si elle est encore valide. */
export function getCurrentToken() {
  return new Promise((resolve) => {
    const user = userPool.getCurrentUser();
    if (!user) return resolve(null);
    user.getSession((err, session) => {
      if (err || !session.isValid()) return resolve(null);
      resolve(session.getIdToken().getJwtToken());
    });
  });
}

export function signOut() {
  const user = userPool.getCurrentUser();
  if (user) user.signOut();
}
