console.log('Vite ⚡️ Rails');

import './application.css';

// React Setup for modern dashboard components
import React from 'react';
import { createRoot } from 'react-dom/client';
import TreatmentNoteTemplateForm from '../components/TreatmentNoteTemplateForm.jsx';

// Mount components based on element presence
document.addEventListener('DOMContentLoaded', () => {
  // Treatment Note Template Form
  const treatmentNoteTemplateFormElement = document.getElementById('treatment-note-template-form');
  if (treatmentNoteTemplateFormElement) {
    const templateId = treatmentNoteTemplateFormElement.dataset.templateId || null;
    const treatmentNoteTemplatesPath = treatmentNoteTemplateFormElement.dataset.treatmentNoteTemplatesPath || '/treatment_note_templates';

    const root = createRoot(treatmentNoteTemplateFormElement);
    root.render(
      React.createElement(TreatmentNoteTemplateForm, {
        templateId,
        treatmentNoteTemplatesPath
      })
    );
  }
});