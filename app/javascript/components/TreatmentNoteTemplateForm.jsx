import React, { useState, useEffect } from 'react';

const TreatmentNoteTemplateForm = ({ templateId, treatmentNoteTemplatesPath = '/treatment_note_templates' }) => {
    // State
    const [template, setTemplate] = useState({
        name: '',
        content: ''
    });
    const [loading, setLoading] = useState(false);
    const [isSubmitting, setIsSubmitting] = useState(false);
    const [error, setError] = useState(null);
    const [errors, setErrors] = useState({});

    // Helper function to get CSRF token
    const getCSRFToken = () => {
        return document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');
    };

    // Fetch template data if editing
    const fetchTemplate = async () => {
        if (!templateId) return;

        setLoading(true);
        setError(null);

        try {
            const response = await fetch(`/api/treatment_note_templates/${templateId}`, {
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': getCSRFToken()
                }
            });

            if (!response.ok) {
                throw new Error('Failed to fetch template');
            }

            const data = await response.json();
            setTemplate({
                name: data.treatment_note_template.name || '',
                content: data.treatment_note_template.content || ''
            });
        } catch (err) {
            setError(err.message);
        } finally {
            setLoading(false);
        }
    };

    // Form submission
    const handleSubmit = async (e) => {
        e.preventDefault();
        if (isSubmitting) return;

        setIsSubmitting(true);
        setError(null);
        setErrors({});

        try {
            const url = templateId
                ? `/api/treatment_note_templates/${templateId}`
                : '/api/treatment_note_templates';

            const method = templateId ? 'PATCH' : 'POST';

            const response = await fetch(url, {
                method,
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': getCSRFToken(),
                    'Accept': 'application/json'
                },
                body: JSON.stringify({
                    treatment_note_template: {
                        name: template.name,
                        content: template.content
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
                }
            } else {
                if (data.errors) {
                    setErrors(data.errors);
                } else {
                    throw new Error(data.message || 'Failed to save template');
                }
            }
        } catch (err) {
            console.error('Error saving template:', err);
            setError(err.message);
            if (window.Flash) {
                window.Flash.error(err.message || 'An error occurred while saving');
            }
        } finally {
            setIsSubmitting(false);
        }
    };

    // Handle input changes
    const handleInputChange = (e) => {
        const { name, value } = e.target;
        setTemplate(prev => ({
            ...prev,
            [name]: value
        }));
    };

    // Effect for fetching data on mount
    useEffect(() => {
        if (templateId) {
            fetchTemplate();
        }
    }, [templateId]);

    return (
        <section>
            <div className="panel panel-default">
                <div className="panel-body">
                    {loading && <div className="loading">Loading...</div>}
                    {error && !loading && <div className="error">{error}</div>}

                    {!loading && !error && (
                        <form onSubmit={handleSubmit} id="js-form-treatment-template">
                            <div className="row">
                                <div className="col-md-6">
                                    <div className="form-group">
                                        <input
                                            type="text"
                                            name="name"
                                            value={template.name}
                                            onChange={handleInputChange}
                                            placeholder="Template name"
                                            className={`form-control ${errors.name ? 'is-invalid' : ''}`}
                                            required
                                        />
                                        {errors.name && (
                                            <div className="invalid-feedback">{errors.name}</div>
                                        )}
                                    </div>
                                </div>
                            </div>

                            <div className="form-group">
                                <label htmlFor="template-content">Template Content</label>
                                <textarea
                                    id="template-content"
                                    name="content"
                                    value={template.content}
                                    onChange={handleInputChange}
                                    className={`form-control ${errors.content ? 'is-invalid' : ''}`}
                                    rows="10"
                                    placeholder="Enter template content..."
                                />
                                {errors.content && (
                                    <div className="invalid-feedback">{errors.content}</div>
                                )}
                            </div>

                            <div className="mt-15">
                                <button
                                    type="submit"
                                    className="btn btn-primary"
                                    disabled={isSubmitting}
                                >
                                    {isSubmitting ? 'Saving...' : 'Save template'}
                                </button>
                                <a
                                    href={treatmentNoteTemplatesPath}
                                    className="btn btn-white ml-10"
                                >
                                    Back to list
                                </a>
                            </div>
                        </form>
                    )}
                </div>
            </div>
        </section>
    );
};

export default TreatmentNoteTemplateForm;
