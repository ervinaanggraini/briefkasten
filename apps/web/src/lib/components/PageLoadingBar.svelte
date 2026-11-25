<script lang="ts">
import { navigating } from "$app/state"
import LoadingIndicator from "$lib/components/LoadingIndicator.svelte"
import { loading } from "$lib/state/loading"

const isLoading = $derived(Boolean(navigating.to) || $loading.status !== "IDLE")
const label = $derived($loading.message || "Loading...")
</script>

{#if isLoading}
  <div
    class="pointer-events-none fixed inset-x-0 top-0 z-100 h-1 overflow-hidden bg-neutral-200/70 dark:bg-neutral-800/70"
    role="progressbar"
    aria-label={label}
  >
    <div class="loading-bar h-full w-1/3 bg-neutral-900 dark:bg-white"></div>
  </div>
  <div
    class="pointer-events-none fixed bottom-4 right-4 z-100 flex items-center gap-2 rounded-full border border-neutral-200 bg-white/95 px-3.5 py-1.5 text-xs font-medium text-neutral-700 shadow-lg backdrop-blur-sm dark:border-neutral-700 dark:bg-neutral-900/95 dark:text-neutral-200"
    role="status"
    aria-live="polite"
  >
    <LoadingIndicator size="sm" />
    <span>{label}</span>
  </div>
{/if}

<style>
  .loading-bar {
    animation: loading-slide 1.1s ease-in-out infinite;
  }

  @keyframes loading-slide {
    0% {
      transform: translateX(-100%);
    }
    100% {
      transform: translateX(400%);
    }
  }
</style>
