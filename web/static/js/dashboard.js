//
// web/static/js/dashboard.js - Lógica del frontend para el panel de cleodocker
//
document.addEventListener('DOMContentLoaded', () => {

    const updateSystemStatus = async () => {
        try {
            const response = await fetch('/api/system/status');
            if (!response.ok) throw new Error('Network response was not ok');
            const data = await response.json();

            // Actualizar CPU
            document.getElementById('cpu-usage').textContent = `${data.cpu_percent}%`;
            document.getElementById('cpu-progress').style.width = `${data.cpu_percent}%`;

            // Actualizar RAM
            document.getElementById('ram-usage').textContent = `${data.ram_percent}%`;
            document.getElementById('ram-progress').style.width = `${data.ram_percent}%`;
            document.getElementById('ram-details').textContent = `${data.ram_used_gb} GB / ${data.ram_total_gb} GB`;

            // Actualizar Disco
            document.getElementById('disk-usage').textContent = `${data.disk_percent}%`;
            document.getElementById('disk-progress').style.width = `${data.disk_percent}%`;
            document.getElementById('disk-details').textContent = `${data.disk_used_gb} GB / ${data.disk_total_gb} GB`;
            
            // Actualizar Info del Sistema
            document.getElementById('system-info').textContent = `${data.platform} (${data.architecture})`;

        } catch (error) {
            console.error('Error fetching system status:', error);
        }
    };

    const updateContainerList = async () => {
        try {
            const response = await fetch('/api/containers');
            if (!response.ok) throw new Error('Network response was not ok');
            const containers = await response.json();
            
            const containerListBody = document.getElementById('container-list-body');
            if (!containerListBody) return; // Salir si no estamos en la página del dashboard

            if (containers.error) {
                containerListBody.innerHTML = `<tr><td colspan="5" style="color: #e06c75;">${containers.error}</td></tr>`;
                return;
            }

            containerListBody.innerHTML = ''; // Limpiar la lista

            if (containers.length === 0) {
                containerListBody.innerHTML = '<tr><td colspan="5">No se encontraron contenedores.</td></tr>';
                return;
            }

            containers.forEach(c => {
                const statusClass = `status-${c.status.split(' ')[0].toLowerCase()}`; // 'running', 'exited', etc.
                const row = `
                    <tr>
                        <td><span class="status-indicator ${statusClass}"></span>${c.name}</td>
                        <td>${c.id}</td>
                        <td>${c.image}</td>
                        <td>${c.status}</td>
                        <td>
                            <button class="btn" onclick="handleContainerAction('${c.id}', 'start')" title="Iniciar">▶</button>
                            <button class="btn" onclick="handleContainerAction('${c.id}', 'stop')" title="Detener">■</button>
                            <button class="btn" onclick="handleContainerAction('${c.id}', 'restart')" title="Reiniciar">↻</button>
                            <button class="btn btn-danger" onclick="handleContainerAction('${c.id}', 'remove')" title="Eliminar">✖</button>
                        </td>
                    </tr>
                `;
                containerListBody.innerHTML += row;
            });
        } catch (error) {
            console.error('Error fetching container list:', error);
        }
    };

    // Función global para manejar acciones de contenedores
    window.handleContainerAction = async (containerId, action) => {
        if (action === 'remove' && !confirm(`¿Estás seguro de que quieres eliminar el contenedor ${containerId}? Esta acción no se puede deshacer.`)) {
            return;
        }

        try {
            const response = await fetch(`/api/containers/${containerId}/${action}`, {
                method: 'POST',
            });
            const result = await response.json();
            
            if (response.ok) {
                console.log(result.message);
                // Refrescar la lista de contenedores después de la acción
                updateContainerList();
            } else {
                alert(`Error: ${result.error}`);
            }
        } catch (error) {
            console.error(`Error performing action ${action} on ${containerId}:`, error);
            alert('Ocurrió un error al comunicarse con el servidor.');
        }
    };

    // Actualizar datos periódicamente si estamos en el dashboard
    if (document.getElementById('dashboard-page')) {
        updateSystemStatus();
        updateContainerList();
        setInterval(updateSystemStatus, 5000); // cada 5 segundos
        setInterval(updateContainerList, 10000); // cada 10 segundos
    }
});