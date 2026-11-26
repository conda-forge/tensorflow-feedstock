// tf_absl_flag_guard.h
//
// Force-included via --per_file_copt (build_common.sh) into TF/XLA TUs that
// define an ABSL_FLAG.
//
// With conda-forge's shared libabseil, registering TF's internal flags into
// the process-global FlagRegistry collides across duplicated TUs inside TF's
// own .so's and with other XLA consumers in the same process such as jaxlib
// (e.g. `leave_barriers_on_recoverable_agent_restart`, which keras triggers
// by importing jax during `import tensorflow`).
//
// Override ABSL_FLAG_IMPL_REGISTRAR with do_register=false (matching abseil's
// ABSL_FLAGS_STRIP_NAMES registrar): FLAGS_<name>, its default value, and
// .OnUpdate() remain intact for absl::GetFlag while skipping global
// FlagRegistry insertion. Matches upstream TF wheels, which link abseil
// statically and never register internal flags in an external registry.
//
// Self-guarded to non-CUDA C++; installed into $PREFIX/include for bare-name
// -include and removed before packaging.

#ifndef TF_ABSL_FLAG_GUARD_H_
#define TF_ABSL_FLAG_GUARD_H_

#if defined(__cplusplus) && !defined(__CUDACC__)

#include "absl/flags/flag.h"

#ifdef ABSL_FLAG_IMPL_REGISTRAR
#undef ABSL_FLAG_IMPL_REGISTRAR
#define ABSL_FLAG_IMPL_REGISTRAR(T, flag)                       \
  absl::flags_internal::FlagRegistrar<T, /*do_register=*/false>( \
      ABSL_FLAG_IMPL_FLAG_PTR(flag), ABSL_FLAG_IMPL_FILENAME())
#endif  // ABSL_FLAG_IMPL_REGISTRAR

#endif  // __cplusplus && !__CUDACC__

#endif  // TF_ABSL_FLAG_GUARD_H_
