#pragma once
#include <chrono>
#include <future>
#include <memory>
#include <thread>

namespace iplug {
namespace detail {
// Final process shutdown only. The caller closes its editor on the UI thread
// first. Stop runs on a worker; successful destruction stays on the caller's
// thread. If a driver wedges, retain the ENTIRE owner (including callback user
// data) until process exit. Releasing only RtAudio would leave dangling host
// pointers. This is deliberately not a device-switch/reinitialization helper.
template <typename Owner, typename Stop>
bool FinishOwnedShutdown(std::unique_ptr<Owner> owner, Stop stop,
                         std::chrono::milliseconds timeout) {
  if (!owner) return true;
  auto done = std::make_shared<std::promise<bool>>();
  auto completion = done->get_future();
  auto* raw = owner.get();
  std::thread worker([raw, stop, done]() {
    try { stop(*raw); done->set_value(true); }
    catch (...) { done->set_value(false); }
  });
  if (completion.wait_for(timeout) == std::future_status::ready) {
    worker.join();
    if (completion.get()) return true; // owner destructs on caller thread
  } else {
    worker.detach();
  }
  // The callback and/or worker may still reference any part of this host.
  // The enclosing standalone must now exit, without reusing the host.
  (void) owner.release();
  return false;
}
} // namespace detail
} // namespace iplug
