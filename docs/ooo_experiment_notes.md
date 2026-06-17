# OOO Experiment Notes

The final integrated OOO experiment combines three earlier ideas:

- Tomasulo-style reservation stations for readiness-based issue
- ROB-based in-order architectural commit
- LSQ-based conservative memory ordering

The design uses ROB tags as the common dependency namespace. Register-status entries point to ROB tags. RS and LSQ source operands wake when the CDB broadcasts the matching ROB tag.

Completion is not commit. Completion means a result has been produced and placed into the ROB. Commit means the ROB head updates architectural register or memory state.

Stores are deliberately conservative: they update memory only at ROB commit. Loads are also conservative: they wait behind older unresolved stores.
