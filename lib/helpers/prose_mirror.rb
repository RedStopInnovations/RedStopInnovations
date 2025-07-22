require 'json'
module ProseMirror
    # Define a mini schema-like structure for nodes and marks
    NODE_RENDERERS = {
    'paragraph' => ->(node, children) {
        style = node.dig('attrs', 'textAlign') ? " style=\"text-align: #{node['attrs']['textAlign']}\"" : ''
        "<p#{style}>#{children}</p>"
    },
    'heading' => ->(node, children) {
        level = node.dig('attrs', 'level') || 1
        style = node.dig('attrs', 'textAlign') ? " style=\"text-align: #{node['attrs']['textAlign']}\"" : ''
        "<h#{level}#{style}>#{children}</h#{level}>"
    },
    'bulletList' => ->(_node, children) { "<ul>#{children}</ul>" },
    'orderedList' => ->(_node, children) { "<ol>#{children}</ol>" },
    'listItem' => ->(_node, children) { "<li>#{children}</li>" },
    'image' => ->(node, _children) {
        # src = node.dig('attrs', 'src') || ''
        # alt = node.dig('attrs', 'alt') || ''
        # title = node.dig('attrs', 'title') || ''
        # "<img src=\"#{src}\" alt=\"#{alt}\" title=\"#{title}\" />"
        "" # Ignore images for now
    },
    'table' => ->(_node, children) { "<table border=\"1\" cellspacing=\"0\" cellpadding=\"5\">#{children}</table>" },
    'tableRow' => ->(_node, children) { "<tr>#{children}</tr>" },
    'tableCell' => ->(node, children) {
        attrs = node['attrs'] || {}
        colspan = attrs['colspan'] && attrs['colspan'] > 1 ? " colspan=\"#{attrs['colspan']}\"" : ''
        rowspan = attrs['rowspan'] && attrs['rowspan'] > 1 ? " rowspan=\"#{attrs['rowspan']}\"" : ''
        style = attrs['backgroundColor'] ? " style=\"background-color: #{attrs['backgroundColor']}\"" : ''
        "<td#{colspan}#{rowspan}#{style}>#{children}</td>"
    }
    }

    MARK_RENDERERS = {
    'bold' => ->(inner) { "<strong>#{inner}</strong>" },
    'italic' => ->(inner) { "<em>#{inner}</em>" },
    'underline' => ->(inner) { "<u>#{inner}</u>" },
    'code' => ->(inner) { "<code>#{inner}</code>" },
    'textStyle' => ->(inner, attrs) {
        styles = []
        styles << "color: #{attrs['color']}" if attrs['color']
        styles << "background-color: #{attrs['backgroundColor']}" if attrs['backgroundColor']
        styles << "font-size: #{attrs['fontSize']}" if attrs['fontSize']
        styles << "font-family: #{attrs['fontFamily']}" if attrs['fontFamily']
        style = styles.any? ? " style=\"#{styles.join('; ')}\"" : ''
        "<span#{style}>#{inner}</span>"
    },
    'link' => ->(inner, attrs) {
        href = attrs['href'] || '#'
        rel = attrs['rel'] ? " rel=\"#{attrs['rel']}\"" : ''
        target = attrs['target'] ? " target=\"#{attrs['target']}\"" : ''
        "<a href=\"#{href}\"#{rel}#{target}>#{inner}</a>"
    }
    }

    def self.serialize_node(node)
        type = node['type']
        children = (node['content'] || []).map { |child| self.serialize_node(child) }.join

        if type == 'text'
            text = node['text'] || ''
            marks = node['marks'] || []
            marks.reduce(text) do |acc, mark|
            mark_type = mark['type']
            renderer = MARK_RENDERERS[mark_type]
            if renderer
                # Check if renderer expects 2 arguments (for textStyle and link)
                if ['textStyle', 'link'].include?(mark_type)
                renderer.call(acc, mark['attrs'] || {})
                else
                renderer.call(acc)
                end
            else
                acc
            end
            end
        else
            renderer = NODE_RENDERERS[type]
            renderer ? renderer.call(node, children) : children
        end
    end

    # Main function
    def self.serialize_doc(json_data)
        if json_data.is_a?(String)
            doc = JSON.parse(json_data)
        else
            doc = json_data
        end
        doc.map { |node| serialize_node(node) }.join("\n")
    end
end