import { writable } from 'svelte/store';

// Profile type definition
export type Profile = {
  address: string;
  username: string;
  bio: string;
  avatarUrl?: string;
  socialLinks?: string[];
  createdAt: number;
  updatedAt: number;
};

// Store for the current user's profile
export const currentProfile = writable<Profile | null>(null);
// Store for profile loading state
export const isLoadingProfile = writable<boolean>(false);
// Store for profile error messages
export const profileError = writable<string | null>(null);

// Get profile by address
export async function fetchProfile(address: string): Promise<Profile | null> {
  if (!address) return null;

  isLoadingProfile.set(true);
  profileError.set(null);

  try {
    const response = await fetch(`/api/profiles/${address}`);

    if (response.status === 404) {
      return null; // Profile not found
    }

    if (!response.ok) {
      throw new Error(`Failed to fetch profile: ${response.statusText}`);
    }

    const profile = await response.json();
    return profile;
  } catch (error) {
    console.error('Error fetching profile:', error);
    profileError.set(error instanceof Error ? error.message : String(error));
    return null;
  } finally {
    isLoadingProfile.set(false);
  }
}

// Create or update profile
export async function saveProfile(profile: Profile): Promise<boolean> {
  isLoadingProfile.set(true);
  profileError.set(null);

  try {
    const response = await fetch(`/api/profiles`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(profile)
    });

    if (!response.ok) {
      throw new Error(`Failed to save profile: ${response.statusText}`);
    }

    const updatedProfile = await response.json();
    currentProfile.set(updatedProfile);
    return true;
  } catch (error) {
    console.error('Error saving profile:', error);
    profileError.set(error instanceof Error ? error.message : String(error));
    return false;
  } finally {
    isLoadingProfile.set(false);
  }
}

// Load current user's profile
export async function loadCurrentProfile(address: string): Promise<void> {
  if (!address) {
    currentProfile.set(null);
    return;
  }

  const profile = await fetchProfile(address);
  currentProfile.set(profile);
}

// Clear profile on disconnect
export function clearProfile(): void {
  currentProfile.set(null);
  profileError.set(null);
}