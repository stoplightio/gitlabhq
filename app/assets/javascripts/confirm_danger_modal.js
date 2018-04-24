import $ from 'jquery';
import { rstrip } from './lib/utils/common_utils';

function openConfirmDangerModal($form, text) {
  $('.js-confirm-text').text(text || '');
  $('.js-confirm-danger-input').val('');
  $('#modal-confirm-danger').modal('show');

  const confirmTextMatch = $('.js-confirm-danger-match').text();
  const $submit = $('.js-confirm-danger-submit');
  $submit.disable();

  $('.js-confirm-danger-input').off('input').on('input', function handleInput() {
    const confirmText = rstrip($(this).val());
    if (confirmText === confirmTextMatch) {
      $submit.enable();
    } else {
      $submit.disable();
    }
  });
  $('.js-confirm-danger-submit').off('click').on('click', () => $form.submit());
}

export default function initConfirmDangerModal() {
  $(document).on('click', '.js-confirm-danger', (e) => {
    e.preventDefault();
    const $btn = $(e.target);
    const $form = $btn.closest('form');
    const text = $btn.data('confirmDangerMessage');
    openConfirmDangerModal($form, text);
  });
}
