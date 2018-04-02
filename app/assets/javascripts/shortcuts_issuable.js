import Mousetrap from 'mousetrap';
import _ from 'underscore';
import Sidebar from './right_sidebar';
import Shortcuts from './shortcuts';
import { CopyAsGFM } from './behaviors/copy_as_gfm';

export default class ShortcutsIssuable extends Shortcuts {
  constructor(isMergeRequest) {
    super();

    this.$replyField = isMergeRequest ? $('.js-main-target-form #note_note') : $('.js-main-target-form .js-vue-comment-form');

    Mousetrap.bind('a', () => ShortcutsIssuable.openSidebarDropdown('assignee'));
    Mousetrap.bind('m', () => ShortcutsIssuable.openSidebarDropdown('milestone'));
    Mousetrap.bind('l', () => ShortcutsIssuable.openSidebarDropdown('labels'));
    Mousetrap.bind('r', this.replyWithSelectedText.bind(this));
    Mousetrap.bind('e', ShortcutsIssuable.editIssue);

    if (isMergeRequest) {
      this.enabledHelp.push('.hidden-shortcut.merge_requests');
    } else {
      this.enabledHelp.push('.hidden-shortcut.issues');
    }
  }

  replyWithSelectedText() {
    const documentFragment = window.gl.utils.getSelectedFragment();

    if (!documentFragment) {
      this.$replyField.focus();
      return false;
    }

    const el = CopyAsGFM.transformGFMSelection(documentFragment.cloneNode(true));
    const selected = CopyAsGFM.nodeToGFM(el);

    if (selected.trim() === '') {
      return false;
    }

    const quote = _.map(selected.split('\n'), val => `${(`> ${val}`).trim()}\n`);

    // If replyField already has some content, add a newline before our quote
    const separator = (this.$replyField.val().trim() !== '' && '\n\n') || '';
    this.$replyField.val((a, current) => `${current}${separator}${quote.join('')}\n`)
      .trigger('input')
      .trigger('change');

    // Trigger autosize
    const event = document.createEvent('Event');
    event.initEvent('autosize:update', true, false);
    this.$replyField.get(0).dispatchEvent(event);

    // Focus the input field
    this.$replyField.focus();

    return false;
  }

  static editIssue() {
    // Need to click the element as on issues, editing is inline
    // on merge request, editing is on a different page
    document.querySelector('.js-issuable-edit').click();

    return false;
  }

  static openSidebarDropdown(name) {
    Sidebar.instance.openDropdown(name);
    return false;
  }
}
