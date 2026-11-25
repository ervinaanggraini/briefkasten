import { betterAuth } from "better-auth"
import { prismaAdapter } from "better-auth/adapters/prisma"
import { APIError, createAuthMiddleware } from "better-auth/api"
import { username } from "better-auth/plugins"
import { sveltekitCookies } from "better-auth/svelte-kit"
import { z } from "zod"
import { getRequestEvent } from "$app/server"
import { env } from "$env/dynamic/private"
import { db } from "$lib/prisma"

export const auth = betterAuth({
  // Must be the exact public URL the browser uses (https://<domain> behind
  // Cloudflare/traefik). OAuth redirect_uri and the state cookie derive from it.
  baseURL: env.BETTER_AUTH_URL,
  trustedOrigins: env.BETTER_AUTH_URL ? [env.BETTER_AUTH_URL] : [],
  database: prismaAdapter(db, {
    provider: "postgresql",
  }),
  plugins: [username(), sveltekitCookies(getRequestEvent)],
  emailAndPassword: {
    enabled: true,
  },
  hooks: {
    before: createAuthMiddleware(async (ctx) => {
      if (ctx.path !== "/sign-in/email") {
        return
      }
      const email = typeof ctx.body?.email === "string" ? ctx.body.email.trim().toLowerCase() : ""
      if (!email || !z.email().safeParse(email).success) {
        return
      }
      const existingUser = await ctx.context.internalAdapter.findUserByEmail(email)
      if (!existingUser) {
        throw new APIError("BAD_REQUEST", {
          code: "USER_NOT_FOUND",
          message: "No account found with this email. Please sign up first.",
        })
      }
    }),
  },
  advanced: {
    // Secure cookies when served over https (the public scheme behind the
    // proxy). Tied to the scheme so plain-http local runs still work.
    useSecureCookies: env.BETTER_AUTH_URL?.startsWith("https://") ?? false,
  },
  socialProviders: {
    google: {
      clientId: env.GOOGLE_CLIENT_ID ?? "",
      clientSecret: env.GOOGLE_CLIENT_SECRET ?? "",
    },
    github: {
      clientId: env.GITHUB_CLIENT_ID ?? "",
      clientSecret: env.GITHUB_CLIENT_SECRET ?? "",
    },
  },
  session: {
    cookieCache: {
      enabled: true,
      maxAge: 5 * 60, // Cache duration in seconds
    },
  },
})
