import { Node, mergeAttributes } from '@tiptap/core';

// Custom YesNo extension
export const YesNo = Node.create({
  name: 'yesNo',

  group: 'block',

  content: '',

  atom: true,

  addAttributes() {
    return {
      id: {
        default: null,
        parseHTML: element => element.getAttribute('data-id'),
        renderHTML: attributes => ({
          'data-id': attributes.id,
        }),
      },
      selectedValue: {
        default: null,
        parseHTML: element => {
          const checkedInput = element.querySelector('input[type="radio"]:checked');
          return checkedInput ? checkedInput.value : null;
        },
        renderHTML: attributes => ({
          'data-selected': attributes.selectedValue,
        }),
      },
    };
  },

  parseHTML() {
    return [
      {
        tag: 'div[data-type="yesNo"]',
      },
    ];
  },

  renderHTML({ HTMLAttributes, node }) {
    // Ensure the node has a consistent ID
    let id = node.attrs.id;
    if (!id) {
      id = `yesNo-${Math.random().toString(36).substr(2, 9)}-${Date.now()}`;
      // Update the node attributes to include the generated ID
      node.attrs.id = id;
    }

    const selectedValue = node.attrs.selectedValue;

    return [
      'div',
      mergeAttributes(HTMLAttributes, {
        'contenteditable': 'false',
        'data-id': id,
        'data-type': 'yesNo',
        'data-selected': selectedValue || ''
      }),
      [
        'label',
        [
          'span',
          [
            'input',
            {
              type: 'radio',
              value: 'Yes',
              name: id,
              ...(selectedValue === 'Yes' ? { checked: 'checked' } : {})
            }
          ]
        ],
        ['span', 'Yes']
      ],
      [
        'label',
        [
          'span',
          [
            'input',
            {
              type: 'radio',
              value: 'No',
              name: id,
              ...(selectedValue === 'No' ? { checked: 'checked' } : {})
            }
          ]
        ],
        ['span', 'No']
      ]
    ];
  },

  addNodeView() {
    return ({ node, HTMLAttributes, getPos, editor }) => {
      let id = node.attrs.id;
      if (!id) {
        id = `yesNo-${Math.random().toString(36).substr(2, 9)}-${Date.now()}`;
      }

      const container = document.createElement('div');
      container.setAttribute('contenteditable', 'false');
      container.setAttribute('data-id', id);
      container.setAttribute('data-type', 'yesNo');
      container.setAttribute('data-selected', node.attrs.selectedValue || '');

      // Create Yes label and radio
      const yesLabel = document.createElement('label');
      const yesSpan = document.createElement('span');
      const yesInput = document.createElement('input');
      yesInput.type = 'radio';
      yesInput.value = 'Yes';
      yesInput.name = id;
      yesInput.checked = node.attrs.selectedValue === 'Yes';

      const yesTextSpan = document.createElement('span');
      yesTextSpan.textContent = 'Yes';

      yesSpan.appendChild(yesInput);
      yesLabel.appendChild(yesSpan);
      yesLabel.appendChild(yesTextSpan);

      // Create No label and radio
      const noLabel = document.createElement('label');
      const noSpan = document.createElement('span');
      const noInput = document.createElement('input');
      noInput.type = 'radio';
      noInput.value = 'No';
      noInput.name = id;
      noInput.checked = node.attrs.selectedValue === 'No';

      const noTextSpan = document.createElement('span');
      noTextSpan.textContent = 'No';

      noSpan.appendChild(noInput);
      noLabel.appendChild(noSpan);
      noLabel.appendChild(noTextSpan);

      // Add event listeners
      const handleChange = (value) => {
        if (typeof getPos === 'function') {
          const pos = getPos();

          // Prevent multiple rapid updates
          if (container._isUpdating) return;
          container._isUpdating = true;

          const tr = editor.state.tr.setNodeMarkup(pos, undefined, {
            ...node.attrs,
            selectedValue: value,
          });

          editor.view.dispatch(tr);

          // Reset the updating flag after a brief delay
          setTimeout(() => {
            container._isUpdating = false;
          }, 10);
        }
      };

      yesInput.addEventListener('change', () => {
        if (yesInput.checked) {
          handleChange('Yes');
        }
      });

      noInput.addEventListener('change', () => {
        if (noInput.checked) {
          handleChange('No');
        }
      });

      container.appendChild(yesLabel);
      container.appendChild(noLabel);

      return {
        dom: container,
        update: (updatedNode) => {
          if (updatedNode.type !== node.type) {
            return false;
          }

          // Only update if not currently handling a change
          if (!container._isUpdating) {
            const newSelectedValue = updatedNode.attrs.selectedValue;
            container.setAttribute('data-selected', newSelectedValue || '');
            yesInput.checked = newSelectedValue === 'Yes';
            noInput.checked = newSelectedValue === 'No';
          }

          return true;
        },
      };
    };
  },

  addCommands() {
    return {
      insertYesNo: () => ({ commands }) => {
        const id = `yesNo-${Math.random().toString(36).substr(2, 9)}-${Date.now()}`;
        return commands.insertContent({
          type: this.name,
          attrs: {
            id: id,
            selectedValue: null
          }
        });
      },
    };
  },
});
