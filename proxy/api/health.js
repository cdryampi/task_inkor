export default function handler(req, res) {
  res.status(200).json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    proxy: 'Inkor API Proxy',
    endpoints: [
      '/rpc/get_tareas',
      '/rpc/insert_tarea',
      '/rpc/update_tarea',
      '/rpc/delete_tarea',
    ]
  });
}
