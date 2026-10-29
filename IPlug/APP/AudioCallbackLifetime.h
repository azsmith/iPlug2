#pragma once

#include <mutex>

// The backend owns the userdata lifetime; the host revokes access before any
// potentially blocking backend teardown. Callbacks never wait for that revoke.
template <typename Owner>
struct AudioCallbackLifetime
{
  explicit AudioCallbackLifetime(Owner* value) : owner(value) {}

  void Revoke()
  {
    std::lock_guard<std::mutex> lock(mutex);
    owner = nullptr;
  }

  std::mutex mutex;
  Owner* owner;
  unsigned int outputChannels = 0;
};
