<script lang="ts">
  export let message = "An error occurred";
  export let visible = false;
  export let type = "error"; // error, warning, info

  // Auto-hide after 5 seconds
  let timer: ReturnType<typeof setTimeout> | undefined;

  $: if (visible) {
    clearTimeout(timer);
    timer = setTimeout(() => {
      visible = false;
    }, 5000);
  }

  function close() {
    visible = false;
    clearTimeout(timer);
  }
</script>

{#if visible}
  <div class={`fixed bottom-4 right-4 p-4 rounded-lg shadow-lg transition-all transform duration-300
    ${type === 'error' ? 'bg-red-900 border-red-700' :
    type === 'warning' ? 'bg-yellow-900 border-yellow-700' :
    'bg-blue-900 border-blue-700'}
    border text-white max-w-md`}
  >
    <div class="flex items-start">
      <div class="flex-1">
        <p class="font-medium">{message}</p>
      </div>
      <button
        class="ml-4 text-white"
        on:click={close}
      >
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
          <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
        </svg>
      </button>
    </div>
  </div>
{/if}