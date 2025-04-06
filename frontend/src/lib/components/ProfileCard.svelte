<script lang="ts">
  import { onMount } from 'svelte';
  import {
    currentProfile,
    isLoadingProfile,
    profileError,
    loadCurrentProfile,
    saveProfile,
    type Profile
  } from '../stores/profile';
  import { wallet } from '../stores/wallet';

  export let address: string;

  let isEditing = false;
  let editForm: Profile = {
    address: '',
    username: '',
    bio: '',
    avatarUrl: '',
    socialLinks: [],
    createdAt: 0,
    updatedAt: 0
  };

  let isSaving = false;
  let errorMessage = '';
  let imgError = false;

  // Check if this is the current user's profile
  $: isCurrentUser = $wallet && address && $wallet.toLowerCase() === address.toLowerCase();

  onMount(async () => {
    await loadCurrentProfile(address);
  });

  // Update form when profile changes
  $: if ($currentProfile) {
    editForm = { ...$currentProfile };
  }

  function startEditing() {
    editForm = $currentProfile ? { ...$currentProfile } : {
      address,
      username: '',
      bio: '',
      avatarUrl: '',
      socialLinks: [],
      createdAt: Date.now(),
      updatedAt: Date.now()
    };
    isEditing = true;
  }

  function cancelEditing() {
    isEditing = false;
    errorMessage = '';
  }

  async function handleSaveProfile() {
    if (!editForm.address) editForm.address = address;
    if (!editForm.username.trim()) {
      errorMessage = 'Username is required';
      return;
    }

    isSaving = true;
    errorMessage = '';

    try {
      // Update timestamp
      editForm.updatedAt = Date.now();

      const success = await saveProfile(editForm);
      if (success) {
        isEditing = false;
      } else {
        errorMessage = 'Failed to save profile';
      }
    } catch (error) {
      errorMessage = error instanceof Error ? error.message : String(error);
    } finally {
      isSaving = false;
    }
  }

  // Format links as clickable URLs
  function formatSocialLink(link: string): string {
    if (!link) return '';
    if (link.startsWith('http://') || link.startsWith('https://')) {
      return link;
    }
    return `https://${link}`;
  }

  // Handle image error
  function handleImageError() {
    imgError = true;
  }
</script>

<div class="card p-6 border border-gray-800 rounded-lg">
  {#if $isLoadingProfile}
    <div class="animate-pulse space-y-4">
      <div class="h-12 bg-gray-700 rounded w-1/2"></div>
      <div class="h-4 bg-gray-700 rounded w-3/4"></div>
      <div class="h-4 bg-gray-700 rounded w-1/2"></div>
    </div>
  {:else if $profileError}
    <div class="text-red-400 p-4 bg-red-900/20 rounded">
      <p>Error loading profile: {$profileError}</p>
    </div>
  {:else if isEditing}
    <!-- Edit Profile Form -->
    <form on:submit|preventDefault={handleSaveProfile} class="space-y-4">
      <h2 class="text-xl font-semibold text-white mb-4">Edit Profile</h2>

      {#if errorMessage}
        <div class="text-red-400 p-3 bg-red-900/20 rounded text-sm mb-4">
          {errorMessage}
        </div>
      {/if}

      <div>
        <label for="username" class="block text-sm font-medium text-gray-400 mb-1">Username</label>
        <input
          id="username"
          bind:value={editForm.username}
          type="text"
          class="input w-full bg-gray-900 border border-gray-700 rounded-lg p-2"
          placeholder="Your username"
        />
      </div>

      <div>
        <label for="bio" class="block text-sm font-medium text-gray-400 mb-1">Bio</label>
        <textarea
          id="bio"
          bind:value={editForm.bio}
          class="input w-full min-h-[100px] resize-none bg-gray-900 border border-gray-700 rounded-lg p-2"
          placeholder="Tell us about yourself..."
        ></textarea>
      </div>

      <div>
        <label for="avatarUrl" class="block text-sm font-medium text-gray-400 mb-1">Avatar URL</label>
        <input
          id="avatarUrl"
          bind:value={editForm.avatarUrl}
          type="text"
          class="input w-full bg-gray-900 border border-gray-700 rounded-lg p-2"
          placeholder="https://example.com/your-avatar.png"
        />
      </div>

      <div class="flex gap-2 pt-2">
        <button
          type="button"
          on:click={cancelEditing}
          class="btn-secondary px-4 py-2 rounded-lg"
        >
          Cancel
        </button>
        <button
          type="submit"
          class="btn-primary px-4 py-2 rounded-lg flex items-center"
          disabled={isSaving}
        >
          {#if isSaving}
            <svg class="animate-spin -ml-1 mr-2 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
              <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
            Saving...
          {:else}
            Save Profile
          {/if}
        </button>
      </div>
    </form>
  {:else}
    <!-- Profile Display -->
    <div class="space-y-4">
      <div class="flex justify-between items-start">
        <h2 class="text-xl font-semibold text-white">
          {$currentProfile ? $currentProfile.username : `User ${address.substring(0, 6)}...${address.substring(address.length - 4)}`}
        </h2>

        {#if isCurrentUser}
          <button
            on:click={startEditing}
            class="text-sm text-monad-purple-light hover:text-white flex items-center gap-1 px-2 py-1 rounded-lg hover:bg-monad-purple/20 transition"
          >
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-4 h-4 mr-1">
              <path d="M21.731 2.269a2.625 2.625 0 00-3.712 0l-1.157 1.157 3.712 3.712 1.157-1.157a2.625 2.625 0 000-3.712zM19.513 8.199l-3.712-3.712-12.15 12.15a5.25 5.25 0 00-1.32 2.214l-.8 2.685a.75.75 0 00.933.933l2.685-.8a5.25 5.25 0 002.214-1.32L19.513 8.2z" />
            </svg>
            Edit
          </button>
        {/if}
      </div>

      <div class="text-gray-400 text-sm font-mono mb-2">
        {address}
      </div>

      {#if $currentProfile}
        {#if $currentProfile.bio}
          <div class="text-gray-300 whitespace-pre-wrap">
            {$currentProfile.bio}
          </div>
        {/if}

        {#if $currentProfile.avatarUrl && !imgError}
          <div class="mt-4">
            <img
              src={$currentProfile.avatarUrl}
              alt={`${$currentProfile.username}'s avatar`}
              class="rounded-lg max-w-[200px] max-h-[200px] border border-gray-700"
              on:error={handleImageError}
            />
          </div>
        {/if}

        {#if $currentProfile.socialLinks && $currentProfile.socialLinks.length > 0}
          <div class="mt-4">
            <h3 class="text-sm font-medium text-gray-400 mb-2">Links</h3>
            <div class="flex flex-wrap gap-2">
              {#each $currentProfile.socialLinks as link}
                <a
                  href={formatSocialLink(link)}
                  target="_blank"
                  rel="noopener noreferrer"
                  class="text-monad-purple-light hover:text-white text-sm bg-monad-purple/10 px-3 py-1 rounded-lg hover:bg-monad-purple/20 transition"
                >
                  {link.replace(/https?:\/\//g, '')}
                </a>
              {/each}
            </div>
          </div>
        {/if}
      {:else if !$isLoadingProfile}
        <div class="text-gray-500 italic">
          {isCurrentUser ? 'You haven\'t created a profile yet.' : 'This user hasn\'t created a profile yet.'}
        </div>

        {#if isCurrentUser}
          <button
            on:click={startEditing}
            class="mt-4 btn-secondary px-4 py-2 rounded-lg flex items-center"
          >
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-4 h-4 mr-2">
              <path d="M21.731 2.269a2.625 2.625 0 00-3.712 0l-1.157 1.157 3.712 3.712 1.157-1.157a2.625 2.625 0 000-3.712zM19.513 8.199l-3.712-3.712-12.15 12.15a5.25 5.25 0 00-1.32 2.214l-.8 2.685a.75.75 0 00.933.933l2.685-.8a5.25 5.25 0 002.214-1.32L19.513 8.2z" />
            </svg>
            Create Profile
          </button>
        {/if}
      {/if}
    </div>
  {/if}
</div>