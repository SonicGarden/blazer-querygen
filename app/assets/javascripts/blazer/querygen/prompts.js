// Blazer Query Generation UI
(function() {
  'use strict';

  // Initialize when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeQuerygen);
  } else {
    initializeQuerygen();
  }

  function initializeQuerygen() {
    // Find the statement-box form-group container
    const statementBox = document.querySelector('#statement-box.form-group') ||
                        document.querySelector('#statement-box') ||
                        document.querySelector('.form-group');

    if (!statementBox) {
      return;
    }

    // Inject AI query generation UI at the top of statement-box
    injectQuerygenUIInStatementBox(statementBox);
  }

  function injectQuerygenUIInStatementBox(statementBox) {
    // Create container for AI query generation
    const container = document.createElement('div');
    container.className = 'blazer-querygen-container';
    container.style.cssText = 'margin-bottom: 15px; padding: 15px; background: #f8f9fa; border: 1px solid #dee2e6; border-radius: 4px;';

    // Create prompt textarea
    const promptTextarea = document.createElement('textarea');
    promptTextarea.id = 'blazer-querygen-prompt';
    promptTextarea.placeholder = 'Describe your query in natural language (e.g., "Show me the top 10 users by total orders")';
    promptTextarea.style.cssText = 'width: 100%; min-height: 60px; padding: 8px; margin-bottom: 10px; border: 1px solid #ced4da; border-radius: 4px; font-family: inherit;';

    // Create generate button
    const generateBtn = document.createElement('button');
    generateBtn.type = 'button';
    generateBtn.id = 'blazer-querygen-generate-btn';
    generateBtn.textContent = 'Generate Query with AI';
    generateBtn.style.cssText = 'padding: 8px 16px; background: #007bff; color: white; border: none; border-radius: 4px; cursor: pointer; font-weight: 500;';
    generateBtn.addEventListener('click', handleGenerateClick);

    // Create status message element
    const statusMsg = document.createElement('div');
    statusMsg.id = 'blazer-querygen-status';
    statusMsg.style.cssText = 'margin-top: 10px; padding: 8px; border-radius: 4px; display: none;';

    // Assemble UI
    container.appendChild(promptTextarea);
    container.appendChild(generateBtn);
    container.appendChild(statusMsg);

    // Insert at the top of statement-box (as first child)
    statementBox.insertBefore(container, statementBox.firstChild);
  }

  function handleGenerateClick() {
    const promptTextarea = document.getElementById('blazer-querygen-prompt');
    const generateBtn = document.getElementById('blazer-querygen-generate-btn');
    const statusMsg = document.getElementById('blazer-querygen-status');

    const prompt = promptTextarea.value.trim();
    if (!prompt) {
      showStatus('Please enter a prompt', 'error');
      return;
    }

    // Disable button and show loading state
    generateBtn.disabled = true;
    generateBtn.textContent = 'Generating...';
    showStatus('Generating SQL query...', 'info');

    // Get data source if available
    const dataSourceSelect = document.querySelector('select[name="data_source"]') ||
                             document.querySelector('select[name="query[data_source]"]');
    const dataSource = dataSourceSelect ? dataSourceSelect.value : null;

    // Get CSRF token
    const csrfToken = document.querySelector('meta[name="csrf-token"]');
    const token = csrfToken ? csrfToken.content : '';

    // Make API request
    fetch('/blazer/prompts/run', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': token
      },
      body: JSON.stringify({
        prompt: prompt,
        data_source: dataSource
      })
    })
      .then(response => response.json())
      .then(data => {
        if (data.success) {
          // Set the SQL in Ace Editor
          setEditorValue(data.sql);
          showStatus('Query generated successfully!', 'success');
        } else {
          showStatus('Error: ' + (data.error || 'Unknown error'), 'error');
        }
      })
      .catch(error => {
        showStatus('Network error: ' + error.message, 'error');
      })
      .finally(() => {
        // Re-enable button
        generateBtn.disabled = false;
        generateBtn.textContent = 'Generate Query with AI';
      });
  }

  function setEditorValue(sql) {
    // Try to find and set value in Ace Editor
    const aceEditor = document.querySelector('.ace_editor');

    if (aceEditor && window.ace) {
      // Get Ace editor instance
      const editor = ace.edit(aceEditor);
      if (editor) {
        editor.setValue(sql, -1); // -1 moves cursor to start
        editor.clearSelection();
        return;
      }
    }

    // Fallback: try to find a regular textarea
    const textarea = document.querySelector('textarea[name="statement"]') ||
                    document.querySelector('textarea[name="query[statement]"]');
    if (textarea) {
      textarea.value = sql;
    }
  }

  function showStatus(message, type) {
    const statusMsg = document.getElementById('blazer-querygen-status');
    statusMsg.textContent = message;
    statusMsg.style.display = 'block';

    // Style based on type
    if (type === 'success') {
      statusMsg.style.background = '#d4edda';
      statusMsg.style.color = '#155724';
      statusMsg.style.border = '1px solid #c3e6cb';
    } else if (type === 'error') {
      statusMsg.style.background = '#f8d7da';
      statusMsg.style.color = '#721c24';
      statusMsg.style.border = '1px solid #f5c6cb';
    } else {
      statusMsg.style.background = '#d1ecf1';
      statusMsg.style.color = '#0c5460';
      statusMsg.style.border = '1px solid #bee5eb';
    }

    // Auto-hide success messages after 5 seconds
    if (type === 'success') {
      setTimeout(() => {
        statusMsg.style.display = 'none';
      }, 5000);
    }
  }
})();
