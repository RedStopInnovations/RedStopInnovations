console.log('Vite ⚡️ Rails');

import './application.css';

// Vue 3 Setup for modern dashboard components
import { createApp } from 'vue';
import TreatmentNoteTemplateForm from '../components/TreatmentNoteTemplateForm.vue';

// Mount components based on element presence
document.addEventListener('DOMContentLoaded', () => {
  // Treatment Note Template Form
  const treatmentNoteTemplateFormElement = document.getElementById('treatment-note-template-form');
  if (treatmentNoteTemplateFormElement) {
    const templateId = treatmentNoteTemplateFormElement.dataset.templateId || null;
    const treatmentNoteTemplatesPath = treatmentNoteTemplateFormElement.dataset.treatmentNoteTemplatesPath || '/treatment_note_templates';

    createApp(TreatmentNoteTemplateForm, {
      templateId,
      treatmentNoteTemplatesPath
    }).mount('#treatment-note-template-form');
  }
});