import { createCookieSessionStorage } from 'react-router';
const { getSession, commitSession } = createCookieSessionStorage({
  cookie: {
    name: "_session",
    sameSite: "lax",
    path: "/",
    httpOnly: true,
    secrets: ["dev-session-secret-change-me"],
    secure: false,
    maxAge: 2147483647
  }
});
const session = await getSession();
session.set("userId", "76561198768295440");
const cookieHeader = await commitSession(session);
console.log(cookieHeader);
