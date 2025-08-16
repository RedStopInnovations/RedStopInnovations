<template>
    <section>
        <div class="panel panel-default">
            <div class="panel-body">
                <div
                    v-if="loading"
                    class="loading"
                >Loading...</div>
                <div
                    v-else-if="error"
                    class="error"
                >{{ error }}</div>

                <form
                    v-else
                    @submit.prevent="submitForm"
                    id="js-form-tiptap-editor"
                >
                    <div class="row">
                        <div class="col-md-6">
                            <div class="form-group">
                                <input
                                    type="text"
                                    v-model="template.name"
                                    placeholder="Template name"
                                    class="form-control"
                                    required
                                    :class="{ 'is-invalid': errors.name }"
                                />
                                <div
                                    v-if="errors.name"
                                    class="invalid-feedback"
                                >{{ errors.name }}</div>
                            </div>
                        </div>
                    </div>

                    <TipTapEditor
                        :content="template.content"
                        @update:content="updateContent"
                        @update:htmlContent="updateHtmlContent"
                    />

                    <div class="mt-15">
                        <button
                            type="submit"
                            class="btn btn-primary"
                            :disabled="isSubmitting"
                        >
                            {{ isSubmitting ? 'Saving...' : 'Save template' }}
                        </button>
                        <a
                            :href="treatmentNoteTemplatesPath"
                            class="btn btn-white ml-10"
                        >Back to list</a>
                    </div>
                </form>
            </div>
        </div>
    </section>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue';
import TipTapEditor from './TipTapEditor.vue';

// Props
const props = defineProps({
    templateId: {
        type: String,
        default: null
    },
    treatmentNoteTemplatesPath: {
        type: String,
        default: '/treatment_note_templates'
    }
});

// State
const template = reactive({
    name: '',
    content: '',
    html_content: ''
});

const loading = ref(false);
const isSubmitting = ref(false);
const error = ref(null);
const errors = reactive({});

// Update content from editor
const updateContent = (content) => {
    template.content = content;
};

const updateHtmlContent = (htmlContent) => {
    template.html_content = htmlContent;
};

// Fetch template data if editing
const fetchTemplate = async () => {
    if (!props.templateId) return;

    loading.value = true;
    error.value = null;

    try {
        const response = await fetch(`/api/treatment_note_templates/${props.templateId}`, {
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
            }
        });

        if (!response.ok) {
            throw new Error('Failed to fetch template');
        }

        const data = await response.json();
        template.name = data.treatment_note_template.name || '';
        template.content = data.treatment_note_template.content || '';
        template.html_content = data.treatment_note_template.html_content || '';
    } catch (err) {
        error.value = err.message;
    } finally {
        loading.value = false;
    }
};

// Form submission
async function submitForm() {
    if (isSubmitting.value) return;

    isSubmitting.value = true;
    error.value = null;
    Object.keys(errors).forEach(key => delete errors[key]);

    try {
        const url = props.templateId
            ? `/api/treatment_note_templates/${props.templateId}`
            : '/api/treatment_note_templates';

        const method = props.templateId ? 'PATCH' : 'POST';

        const response = await fetch(url, {
            method,
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content'),
                'Accept': 'application/json'
            },
            body: JSON.stringify({
                treatment_note_template: {
                    name: template.name,
                    content: template.content,
                    html_content: template.html_content
                }
            })
        });

        const data = await response.json();

        if (response.ok) {
            if (window.Flash) {
                window.Flash.success(data.message || 'Template saved successfully');
            }

            if (data.redirect_url) {
                window.location.href = data.redirect_url;
            } else {
                window.location.reload();
                // window.location.href = props.treatmentNoteTemplatesPath;
            }
        } else {
            if (data.errors) {
                Object.assign(errors, data.errors);
            } else {
                throw new Error(data.message || 'Failed to save template');
            }
        }
    } catch (err) {
        console.error('Error saving template:', err);
        error.value = err.message;
        if (window.Flash) {
            window.Flash.error(err.message || 'An error occurred while saving');
        }
    } finally {
        isSubmitting.value = false;
    }
}

// Lifecycle
onMounted(async () => {
    // Fetch data if editing
    if (props.templateId) {
        await fetchTemplate();
    }
});
</script>
