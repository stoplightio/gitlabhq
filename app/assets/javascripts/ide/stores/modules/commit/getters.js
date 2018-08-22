import * as consts from './constants';

const BRANCH_SUFFIX_COUNT = 5;

export const discardDraftButtonDisabled = state =>
  state.commitMessage === '' || state.submitCommitLoading;

export const commitButtonDisabled = (state, getters, rootState) =>
  getters.discardDraftButtonDisabled || !rootState.stagedFiles.length;

export const newBranchName = (state, _, rootState) =>
  `${gon.current_username}-${rootState.currentBranchId}-patch-${`${new Date().getTime()}`.substr(
    -BRANCH_SUFFIX_COUNT,
  )}`;

export const branchName = (state, getters, rootState) => {
  if (
    state.commitAction === consts.COMMIT_TO_NEW_BRANCH ||
    state.commitAction === consts.COMMIT_TO_NEW_BRANCH_MR
  ) {
    if (state.newBranchName === '') {
      return getters.newBranchName;
    }

    return state.newBranchName;
  }

  return rootState.currentBranchId;
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
