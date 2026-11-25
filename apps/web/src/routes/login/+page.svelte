<script lang="ts">
import { tick } from "svelte"
import { toast } from "svelte-sonner"
import { twJoin } from "tailwind-merge"
import { browser } from "$app/environment"
import { goto } from "$app/navigation"
import { page } from "$app/state"
import LoginPattern from "$lib/assets/LoginPattern.svelte"
import { authClient } from "$lib/auth-client"
import LoadingIndicator from "$lib/components/LoadingIndicator.svelte"
import { loading } from "$lib/state/loading"
import ProviderIcons from "./ProviderIcons.svelte"

type AuthFeedback = {
  kind: "warning" | "error"
  message: string
  action?: "signup" | "signin"
}

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

const session = authClient.useSession()

let email = $state("")
let password = $state("")
let name = $state("")
let isSignUp = $state(false)
let isSubmitting = $state(false)
let socialProviderLoading = $state<"github" | "google" | null>(null)
let isSigningOut = $state(false)
let signInFeedback = $state<AuthFeedback | null>(null)
let signUpFeedback = $state<AuthFeedback | null>(null)

const isBusy = $derived(isSubmitting || socialProviderLoading !== null || isSigningOut)

const providerButtonStyles = (provider: string): string => {
  switch (provider) {
    case "github":
      return "bg-neutral-700 text-white"
    case "google":
      return "bg-white focus:ring-blue-700 text-blue-600 border border-gray-300"
    case "azure-ad":
      return "bg-blue-700 hover:bg-blue-900 focus:ring-blue-700 text-white"
    case "authentik":
      return "bg-orange-600 hover:bg-orange-800 text-white"
    case "keycloak":
      return "bg-gray-600 hover:bg-gray-800 text-white"
    default:
      return "bg-gray-600 hover:bg-gray-800 text-white"
  }
}

const switchMode = (signUp: boolean) => {
  isSignUp = signUp
  signInFeedback = null
  signUpFeedback = null
}

const handleSignIn = async (event: SubmitEvent) => {
  event.preventDefault()
  if (isBusy) return

  const trimmedEmail = email.trim()
  if (!trimmedEmail || !password) {
    signInFeedback = {
      kind: "warning",
      message: "Please enter both your email and password.",
    }
    return
  }

  if (!EMAIL_PATTERN.test(trimmedEmail)) {
    signInFeedback = {
      kind: "error",
      message: "Please enter a valid email address.",
    }
    return
  }

  signInFeedback = null
  isSubmitting = true
  loading.setLoading(true, "Signing in...")

  try {
    const result = await authClient.signIn.email({
      email: trimmedEmail,
      password,
    })

    if (result.error) {
      const code = result.error.code
      if (code === "USER_NOT_FOUND") {
        signInFeedback = {
          kind: "warning",
          message: "No account found with this email. Please sign up first.",
          action: "signup",
        }
      } else if (code === "INVALID_EMAIL_OR_PASSWORD") {
        signInFeedback = {
          kind: "error",
          message: "Incorrect email or password. Please try again.",
        }
      } else if (code === "INVALID_EMAIL") {
        signInFeedback = {
          kind: "error",
          message: "Please enter a valid email address.",
        }
      } else {
        signInFeedback = {
          kind: "error",
          message: result.error.message || "Unable to sign in. Please try again.",
        }
      }
      return
    }

    await goto(page.data.redirectTo ?? "/")
  } catch {
    signInFeedback = {
      kind: "error",
      message: "Something went wrong while signing in. Please try again.",
    }
  } finally {
    isSubmitting = false
    loading.setLoading(false)
  }
}

const handleSignUp = async (event: SubmitEvent) => {
  event.preventDefault()
  if (isBusy) return

  const trimmedName = name.trim()
  const trimmedEmail = email.trim()

  if (!trimmedName || !trimmedEmail || !password) {
    signUpFeedback = {
      kind: "warning",
      message: "Please fill in your name, email, and password.",
    }
    return
  }

  if (!EMAIL_PATTERN.test(trimmedEmail)) {
    signUpFeedback = {
      kind: "error",
      message: "Please enter a valid email address.",
    }
    return
  }

  if (password.length < 8) {
    signUpFeedback = {
      kind: "warning",
      message: "Password must be at least 8 characters long.",
    }
    return
  }

  signUpFeedback = null
  isSubmitting = true
  loading.setLoading(true, "Creating account...")

  try {
    const result = await authClient.signUp.email({
      name: trimmedName,
      email: trimmedEmail,
      password,
    })

    if (result.error) {
      const code = result.error.code
      if (code === "USER_ALREADY_EXISTS" || code === "USER_ALREADY_EXISTS_USE_ANOTHER_EMAIL") {
        signUpFeedback = {
          kind: "warning",
          message: "An account with this email already exists. Please sign in instead.",
          action: "signin",
        }
      } else if (code === "PASSWORD_TOO_SHORT") {
        signUpFeedback = {
          kind: "warning",
          message: "Password is too short. Please use at least 8 characters.",
        }
      } else if (code === "INVALID_EMAIL") {
        signUpFeedback = {
          kind: "error",
          message: "Please enter a valid email address.",
        }
      } else {
        signUpFeedback = {
          kind: "error",
          message: result.error.message || "Unable to create account. Please try again.",
        }
      }
      return
    }

    await goto(page.data.redirectTo ?? "/")
  } catch {
    signUpFeedback = {
      kind: "error",
      message: "Something went wrong while creating your account. Please try again.",
    }
  } finally {
    isSubmitting = false
    loading.setLoading(false)
  }
}

const handleSocialSignIn = async (provider: "github" | "google") => {
  if (isBusy) return
  signInFeedback = null
  socialProviderLoading = provider
  loading.setLoading(true, `Connecting to ${provider === "github" ? "GitHub" : "Google"}...`)

  try {
    const result = await authClient.signIn.social({
      provider,
      callbackURL: page.data.redirectTo ?? "/",
    })

    if (result?.error) {
      signInFeedback = {
        kind: "error",
        message: result.error.message || `Unable to sign in with ${provider}.`,
      }
      socialProviderLoading = null
      loading.setLoading(false)
    }
  } catch {
    signInFeedback = {
      kind: "error",
      message: `Unable to sign in with ${provider}. Please try again.`,
    }
    socialProviderLoading = null
    loading.setLoading(false)
  }
}

const handleSignOut = async () => {
  if (isBusy) return
  isSigningOut = true
  loading.setLoading(true, "Signing out...")
  try {
    await authClient.signOut({})
  } finally {
    isSigningOut = false
    loading.setLoading(false)
  }
}

if (browser && page.url.searchParams.get("verifyEmail")) {
  void tick().then(() => {
    toast.success("Email sent, please check your inbox!", {
      position: "top-left",
      classes: {
        toast: "bg-neutral-700/20 text-white border-gray-400/10",
      },
    })
  })
}
</script>

<div class="flex overflow-hidden relative w-full h-full">
  <LoginPattern
    class="object-cover fixed top-0 right-0 min-w-full min-h-full bg-white z-5"
  />
  <div
    aria-label="Slate cover background"
    class="absolute left-0 top-0 z-10 flex h-[275%] w-[150%] translate-x-[-70%] translate-y-[-28%] rotate-30 items-center bg-neutral-950 md:translate-y-[-15%] md:rotate-11"
  ></div>
  <div
    class="h-dvh z-20 flex w-full items-center justify-center md:ml-[15%] md:w-[22rem]"
  >
    <div class="flex flex-col justify-center items-center w-80 text-xl">
      <h2
        class="flex items-center mb-8 space-x-2 text-3xl font-light text-neutral-600"
      >
        <svg
          class="text-white rounded-md size-12"
          width="250"
          height="250"
          viewBox="0 0 250 250"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <rect width="250" height="250" rx="8" fill="#1E1E1E" />
          <path
            d="M90.4679 198.601H56.8679V51.6012H82.4879C100.968 51.6012 114.898 55.0312 124.278 61.8912C133.658 68.6112 138.348 78.1312 138.348 90.4512C138.348 104.451 132.468 114.741 120.708 121.321C137.788 127.761 146.328 139.871 146.328 157.651C146.328 170.251 141.708 180.261 132.468 187.681C123.228 194.961 109.228 198.601 90.4679 198.601ZM90.4679 192.301C97.0479 192.301 103.068 191.811 108.528 190.831C113.988 189.711 119.168 187.961 124.068 185.581C129.108 183.061 133.028 179.421 135.828 174.661C138.628 169.901 140.028 164.231 140.028 157.651C140.028 142.671 132.818 132.521 118.398 127.201L105.798 122.581L117.558 115.861C127.218 110.541 132.048 102.071 132.048 90.4512C132.048 68.7512 115.528 57.9012 82.4879 57.9012H63.1679V192.301H90.4679Z"
            fill="white"
          />
          <rect x="122.032" width="125.968" height="248.466" fill="#1E1E1E" />
          <path
            d="M151.084 198H117.484V51H143.104C161.584 51 175.514 54.43 184.894 61.29C194.274 68.01 198.964 77.53 198.964 89.85C198.964 103.85 193.084 114.14 181.324 120.72C198.404 127.16 206.944 139.27 206.944 157.05C206.944 169.65 202.324 179.66 193.084 187.08C183.844 194.36 169.844 198 151.084 198ZM151.084 191.7C157.664 191.7 163.684 191.21 169.144 190.23C174.604 189.11 179.784 187.36 184.684 184.98C189.724 182.46 193.644 178.82 196.444 174.06C199.244 169.3 200.644 163.63 200.644 157.05C200.644 142.07 193.434 131.92 179.014 126.6L166.414 121.98L178.174 115.26C187.834 109.94 192.664 101.47 192.664 89.85C192.664 68.15 176.144 57.3 143.104 57.3H123.784V191.7H151.084Z"
            fill="white"
          />
        </svg>
        <span class="text-4xl font-medium text-white">Briefkasten</span>
      </h2>
      <div class="flip-card m-8 w-full">
        <div class="flip-card-inner" class:flipped={isSignUp}>
          <!-- Front side - Sign In -->
          <div
            class="flip-card-front flex flex-col gap-2 p-6 w-full bg-white rounded shadow-lg"
          >
            {#if !$session.data}
              <form
                novalidate
                onsubmit={handleSignIn}
                class="flex flex-col justify-center items-stretch space-y-2 w-full focus:outline-none [&>button]:transition focus:[&>button]:outline-none focus:[&>button]:ring-2 focus:[&>button]:ring-offset-2 focus:[&>button]:ring-zinc-300 [&>button]:rounded-sm"
              >
                <input
                  id="email"
                  type="email"
                  name="email"
                  autocomplete="email"
                  bind:value={email}
                  oninput={() => (signInFeedback = null)}
                  disabled={isBusy}
                  placeholder="user@company.com"
                  class="flex py-2 px-3 w-full text-sm bg-transparent rounded-sm border ring-offset-white transition focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:outline-none border-neutral-300 placeholder:text-neutral-400 text-neutral-900 focus-visible:ring-zinc-300 disabled:opacity-50"
                  required
                />
                <input
                  id="password"
                  type="password"
                  name="password"
                  autocomplete="current-password"
                  bind:value={password}
                  oninput={() => (signInFeedback = null)}
                  disabled={isBusy}
                  placeholder="Password"
                  class="flex py-2 px-3 w-full text-sm bg-transparent rounded-sm border ring-offset-white transition focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:outline-none border-neutral-300 placeholder:text-neutral-400 text-neutral-900 focus-visible:ring-zinc-300 disabled:opacity-50"
                  required
                />
                {#if signInFeedback}
                  <div
                    role="alert"
                    class={twJoin(
                      "flex items-start gap-2 rounded-sm border px-3 py-2 text-xs leading-relaxed",
                      signInFeedback.kind === "warning"
                        ? "border-amber-300 bg-amber-50 text-amber-900"
                        : "border-red-300 bg-red-50 text-red-800",
                    )}
                  >
                    <svg
                      class="mt-0.5 size-4 shrink-0"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      aria-hidden="true"
                    >
                      <path
                        d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3"
                      />
                      <path d="M12 9v4" />
                      <path d="M12 17h.01" />
                    </svg>
                    <div class="flex flex-col gap-1">
                      <span>{signInFeedback.message}</span>
                      {#if signInFeedback.action === "signup"}
                        <button
                          type="button"
                          class="self-start font-semibold underline underline-offset-2 hover:opacity-80"
                          onclick={() => switchMode(true)}
                        >
                          Sign up now
                        </button>
                      {/if}
                    </div>
                  </div>
                {/if}
                <button
                  type="submit"
                  disabled={isBusy}
                  class="flex overflow-hidden justify-center items-center px-4 space-x-2 w-full h-10 text-sm font-light text-white rounded-sm transition focus:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 bg-neutral-700 hover:bg-neutral-800 ring-offset-background focus-visible:ring-zinc-300 disabled:opacity-60 disabled:cursor-not-allowed"
                >
                  {#if isSubmitting}
                    <LoadingIndicator size="sm" />
                    <span>Signing in...</span>
                  {:else}
                    <span>Continue</span>
                  {/if}
                </button>
              </form>

              <div class="flex gap-2 items-center my-2">
                <div class="flex-1 bg-neutral-300 h-px"></div>
                <span class="text-xs leading-4 uppercase text-neutral-500"
                  >or</span
                >
                <div class="flex-1 bg-neutral-300 h-px"></div>
              </div>
              <button
                type="button"
                disabled={isBusy}
                onclick={() => handleSocialSignIn("github")}
                class="w-full *:w-full disabled:opacity-60 disabled:cursor-not-allowed [&>button]:transition focus:[&>button]:outline-none focus:[&>button]:ring-2 focus:[&>button]:ring-offset-2 focus:[&>button]:ring-zinc-300 [&>button]:rounded-sm"
              >
                <div
                  class={twJoin(
                    "flex h-10 w-full items-center space-x-2 rounded px-4 text-base font-light transition focus:outline-none focus:ring-2 focus:ring-offset-2 group overflow-hidden focus-visible:ring-zinc-300",
                    providerButtonStyles("github"),
                  )}
                >
                  {#if socialProviderLoading === "github"}
                    <div class="flex w-full items-center justify-center gap-2 text-sm">
                      <LoadingIndicator size="sm" />
                      <span>Redirecting...</span>
                    </div>
                  {:else}
                    <div
                      class="inline-flex relative items-center w-full transition -translate-x-0 group-hover:-translate-x-6 group-focus-visible:-translate-x-6"
                    >
                      <div
                        class="absolute opacity-100 transition translate-x-0 group-hover:opacity-0 group-hover:-translate-x-6 group-focus-visible:-translate-x-6"
                      >
                        <ProviderIcons provider="github" />
                      </div>
                      <span class="flex justify-center w-full text-sm">
                        Continue with GitHub
                      </span>
                      <div
                        class="absolute right-0 opacity-0 transition translate-x-12 group-hover:opacity-100 group-hover:translate-x-6 group-focus-visible:translate-x-6"
                      >
                        <svg
                          width="15"
                          height="15"
                          viewBox="0 0 15 15"
                          fill="none"
                          xmlns="http://www.w3.org/2000/svg"
                          class="w-5 h-5"
                        >
                          <path
                            d="M8.14645 3.14645C8.34171 2.95118 8.65829 2.95118 8.85355 3.14645L12.8536 7.14645C13.0488 7.34171 13.0488 7.65829 12.8536 7.85355L8.85355 11.8536C8.65829 12.0488 8.34171 12.0488 8.14645 11.8536C7.95118 11.6583 7.95118 11.3417 8.14645 11.1464L11.2929 8H2.5C2.22386 8 2 7.77614 2 7.5C2 7.22386 2.22386 7 2.5 7H11.2929L8.14645 3.85355C7.95118 3.65829 7.95118 3.34171 8.14645 3.14645Z"
                            fill="currentColor"
                            fill-rule="evenodd"
                            clip-rule="evenodd"
                          >
                          </path>
                        </svg>
                      </div>
                    </div>
                  {/if}
                </div>
              </button>
              <button
                type="button"
                disabled={isBusy}
                onclick={() => handleSocialSignIn("google")}
                class="w-full *:w-full disabled:opacity-60 disabled:cursor-not-allowed [&>button]:transition focus:[&>button]:outline-none focus:[&>button]:ring-2 focus:[&>button]:ring-offset-2 focus:[&>button]:ring-zinc-300 [&>button]:rounded-sm"
              >
                <div
                  class={twJoin(
                    "flex h-10 w-full items-center space-x-2 rounded px-4 text-base font-light transition focus:outline-none focus:ring-2 focus:ring-offset-2 group overflow-hidden focus-visible:ring-zinc-300",
                    providerButtonStyles("google"),
                  )}
                >
                  {#if socialProviderLoading === "google"}
                    <div class="flex w-full items-center justify-center gap-2 text-sm">
                      <LoadingIndicator size="sm" />
                      <span>Redirecting...</span>
                    </div>
                  {:else}
                    <div
                      class="inline-flex relative items-center w-full transition -translate-x-0 group-hover:-translate-x-6 group-focus-visible:-translate-x-6"
                    >
                      <div
                        class="absolute opacity-100 transition translate-x-0 group-hover:opacity-0 group-hover:-translate-x-6 group-focus-visible:-translate-x-6"
                      >
                        <ProviderIcons provider="google" />
                      </div>
                      <span class="flex justify-center w-full text-sm">
                        Continue with Google
                      </span>
                      <div
                        class="absolute right-0 opacity-0 transition translate-x-12 group-hover:opacity-100 group-hover:translate-x-6 group-focus-visible:translate-x-6"
                      >
                        <svg
                          width="15"
                          height="15"
                          viewBox="0 0 15 15"
                          fill="none"
                          xmlns="http://www.w3.org/2000/svg"
                          class="w-5 h-5"
                        >
                          <path
                            d="M8.14645 3.14645C8.34171 2.95118 8.65829 2.95118 8.85355 3.14645L12.8536 7.14645C13.0488 7.34171 13.0488 7.65829 12.8536 7.85355L8.85355 11.8536C8.65829 12.0488 8.34171 12.0488 8.14645 11.8536C7.95118 11.6583 7.95118 11.3417 8.14645 11.1464L11.2929 8H2.5C2.22386 8 2 7.77614 2 7.5C2 7.22386 2.22386 7 2.5 7H11.2929L8.14645 3.85355C7.95118 3.65829 7.95118 3.34171 8.14645 3.14645Z"
                            fill="currentColor"
                            fill-rule="evenodd"
                            clip-rule="evenodd"
                          >
                          </path>
                        </svg>
                      </div>
                    </div>
                  {/if}
                </div>
              </button>

              <!-- Toggle to Sign Up -->
              <div class="flex justify-center items-center mt-4 text-sm">
                <span class="text-neutral-600">Don't have an account?</span>
                <button
                  type="button"
                  disabled={isBusy}
                  class="ml-2 text-neutral-900 font-medium hover:underline disabled:opacity-50"
                  onclick={() => switchMode(true)}
                >
                  Sign up
                </button>
              </div>
            {:else}
              <button
                type="button"
                disabled={isBusy}
                class="flex overflow-hidden justify-center items-center px-4 space-x-2 w-full h-10 text-sm font-light text-white rounded-sm transition focus:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 bg-neutral-700 ring-offset-background focus-visible:ring-zinc-300 disabled:opacity-60 disabled:cursor-not-allowed"
                onclick={handleSignOut}
              >
                {#if isSigningOut}
                  <LoadingIndicator size="sm" />
                  <span>Signing out...</span>
                {:else}
                  <span>Sign out</span>
                {/if}
              </button>
            {/if}
          </div>

          <!-- Back side - Sign Up -->
          <div
            class="flip-card-back flex flex-col gap-2 p-6 w-full bg-white rounded shadow-lg"
          >
            {#if !$session.data}
              <h3 class="text-xl font-medium text-neutral-900 mb-2">
                Create Account
              </h3>
              <form
                novalidate
                onsubmit={handleSignUp}
                class="flex flex-col justify-center items-stretch space-y-2 w-full focus:outline-none"
              >
                <input
                  id="signup-name"
                  type="text"
                  name="name"
                  autocomplete="name"
                  bind:value={name}
                  oninput={() => (signUpFeedback = null)}
                  disabled={isBusy}
                  placeholder="John Doe"
                  class="flex py-2 px-3 w-full text-sm bg-transparent rounded-sm border ring-offset-white transition focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:outline-none border-neutral-300 placeholder:text-neutral-400 text-neutral-900 focus-visible:ring-zinc-300 disabled:opacity-50"
                  required
                />
                <input
                  id="signup-email"
                  type="email"
                  name="email"
                  autocomplete="email"
                  bind:value={email}
                  oninput={() => (signUpFeedback = null)}
                  disabled={isBusy}
                  placeholder="user@company.com"
                  class="flex py-2 px-3 w-full text-sm bg-transparent rounded-sm border ring-offset-white transition focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:outline-none border-neutral-300 placeholder:text-neutral-400 text-neutral-900 focus-visible:ring-zinc-300 disabled:opacity-50"
                  required
                />
                <input
                  id="signup-password"
                  type="password"
                  name="password"
                  autocomplete="new-password"
                  bind:value={password}
                  oninput={() => (signUpFeedback = null)}
                  disabled={isBusy}
                  placeholder="Password (min. 8 characters)"
                  class="flex py-2 px-3 w-full text-sm bg-transparent rounded-sm border ring-offset-white transition focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:outline-none border-neutral-300 placeholder:text-neutral-400 text-neutral-900 focus-visible:ring-zinc-300 disabled:opacity-50"
                  required
                />
                {#if signUpFeedback}
                  <div
                    role="alert"
                    class={twJoin(
                      "flex items-start gap-2 rounded-sm border px-3 py-2 text-xs leading-relaxed",
                      signUpFeedback.kind === "warning"
                        ? "border-amber-300 bg-amber-50 text-amber-900"
                        : "border-red-300 bg-red-50 text-red-800",
                    )}
                  >
                    <svg
                      class="mt-0.5 size-4 shrink-0"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      aria-hidden="true"
                    >
                      <path
                        d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3"
                      />
                      <path d="M12 9v4" />
                      <path d="M12 17h.01" />
                    </svg>
                    <div class="flex flex-col gap-1">
                      <span>{signUpFeedback.message}</span>
                      {#if signUpFeedback.action === "signin"}
                        <button
                          type="button"
                          class="self-start font-semibold underline underline-offset-2 hover:opacity-80"
                          onclick={() => switchMode(false)}
                        >
                          Sign in instead
                        </button>
                      {/if}
                    </div>
                  </div>
                {/if}
                <button
                  type="submit"
                  disabled={isBusy}
                  class="flex overflow-hidden justify-center items-center px-4 space-x-2 w-full h-10 text-sm font-light text-white rounded-sm transition focus:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 bg-neutral-700 hover:bg-neutral-800 ring-offset-background focus-visible:ring-zinc-300 disabled:opacity-60 disabled:cursor-not-allowed"
                >
                  {#if isSubmitting}
                    <LoadingIndicator size="sm" />
                    <span>Creating account...</span>
                  {:else}
                    <span>Sign Up</span>
                  {/if}
                </button>
              </form>

              <!-- Toggle back to Sign In -->
              <div class="flex justify-center items-center mt-4 text-sm">
                <span class="text-neutral-600">Already have an account?</span>
                <button
                  type="button"
                  disabled={isBusy}
                  class="ml-2 text-neutral-900 font-medium hover:underline disabled:opacity-50"
                  onclick={() => switchMode(false)}
                >
                  Sign in
                </button>
              </div>
            {/if}
          </div>
        </div>
      </div>
    </div>
  </div>
</div>

<style>
  .flip-card {
    perspective: 1000px;
    min-height: 400px;
  }

  .flip-card-inner {
    position: relative;
    width: 100%;
    height: 100%;
    transition: transform 0.6s;
    transform-style: preserve-3d;
  }

  .flip-card-inner.flipped {
    transform: rotateY(180deg);
  }

  .flip-card-front,
  .flip-card-back {
    width: 100%;
    backface-visibility: hidden;
    -webkit-backface-visibility: hidden;
  }

  .flip-card-back {
    position: absolute;
    top: 0;
    left: 0;
    transform: rotateY(180deg);
  }
</style>
