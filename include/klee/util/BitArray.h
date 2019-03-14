//===-- BitArray.h ----------------------------------------------*- C++ -*-===//
//
//                     The KLEE Symbolic Virtual Machine
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#ifndef KLEE_UTIL_BITARRAY_H
#define KLEE_UTIL_BITARRAY_H

namespace klee {

  // XXX would be nice not to have
  // two allocations here for allocated
  // BitArrays
class BitArray {
private:
  //uint32_t *bits;

  // XXX(s2e) for now we keep this first to access from C code
  // (yes, we do need to access if really fast)
  uint32_t *m_bits;
  unsigned m_refcount;
  unsigned m_bitcount;
  unsigned m_setbitcount;

protected:
  static uint32_t length(unsigned size) { return (size+31)/32; }

public:
  BitArray(unsigned size, bool value = false) : m_bits(new uint32_t[length(size)]) {
    memset(m_bits, value?0xFF:0, sizeof(*m_bits)*length(size));
  }
  BitArray(const BitArray &b, unsigned size) : m_bits(new uint32_t[length(size)]) {
    memcpy(m_bits, b.m_bits, sizeof(*m_bits)*length(size));
  }
  ~BitArray() { delete[] m_bits; }

  bool get(unsigned idx) { return (bool) ((m_bits[idx/32]>>(idx&0x1F))&1); }
  void set(unsigned idx) { m_bits[idx/32] |= 1<<(idx&0x1F); }
  void unset(unsigned idx) { m_bits[idx/32] &= ~(1<<(idx&0x1F)); }
  void set(unsigned idx, bool value) { if (value) set(idx); else unset(idx); }

  bool isAllZeros(unsigned size) const {
      return m_setbitcount == 0;
  }

  bool isAllOnes(unsigned size) const {
      return m_setbitcount == m_bitcount;
  }

};

} // End klee namespace

#endif
