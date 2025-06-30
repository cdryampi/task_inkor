export default async function handler(req, res) {
  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  // Handle preflight requests
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  // Only allow POST requests
  if (req.method !== 'POST') {
    return res.status(405).json({
      error: 'Method not allowed',
      message: 'Only POST requests are allowed'
    });
  }

  // validate environment variables
  try {
    const openaiApiKey = process.env.OPENAI_API_KEY;
    const supabaseUrl = process.env.SUPABASE_URL;
    const supabaseServiceKey = process.env.SUPABASE_ANON_KEY;
    const githubToken = process.env.GITHUB_TOKEN;
    const githubUsername = process.env.GITHUB_USERNAME;

    // Check if the required environment variables are set
    if (!openaiApiKey) {
      console.error('❌ OPENAI_API_KEY not configured');
      return res.status(500).json({
        error: 'Configuration error',
        message: 'OpenAI API key not configured'
      });
    }

    if (!supabaseUrl || !supabaseServiceKey) {
      console.error('❌ Supabase credentials not configured');
      return res.status(500).json({
        error: 'Configuration error',
        message: 'Supabase credentials not configured'
      });
    }

    if (!githubToken) {
      console.error('❌ GitHub token not configured');
      return res.status(500).json({
        error: 'Configuration error',
        message: 'GitHub token not configured'
      });
    }

    if (!githubUsername) {
      console.error('❌ GitHub username not configured');
      return res.status(500).json({
        error: 'Configuration error',
        message: 'GitHub username not configured'
      });
    }

    // Initialize Supabase client for checking issues
    const { createClient } = await import('@supabase/supabase-js');
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Paso 1: filtrar las tareas con tag "motivBotLinkIssuesFromGithub"
    let tasks = [];
    // paso 2: obtener las tareas con tag "motivBotLinkIssuesFromGithub"
    try {
      // Cambiar la consulta para buscar en arrays
      const { data, error } = await supabase
        .from('task')
        .select('*')
        .contains('tags', ['motivBotLinkIssuesFromGithub']);

      if (error) {
        console.error('Error fetching tasks:', error);
        return res.status(500).json({
          error: 'Database error',
          message: 'Failed to fetch tasks from Supabase'
        });
      }
      tasks = data || [];
      console.log(`📋 Found ${tasks.length} existing tasks with motivBotLinkIssuesFromGithub tag`);
    } catch (error) {
      console.error('Error fetching tasks:', error);
      return res.status(500).json({
        error: 'Database error',
        message: 'Failed to fetch tasks from Supabase'
      });
    }

    // Paso 3: recuperar los issues de GitHub
    let issues = [];

    try {
      console.log(`🔍 Fetching repositories for user: ${githubUsername}...`);

      // Paso 3.1: Obtener TODOS los repositorios del usuario con paginación
      let allRepositories = [];
      let page = 1;
      const perPage = 100; // Máximo permitido por GitHub

      while (true) {
        console.log(`📄 Fetching page ${page} of repositories...`);

        const reposResponse = await fetch(
          `https://api.github.com/users/${githubUsername}/repos?per_page=${perPage}&page=${page}&sort=updated&direction=desc&type=all`,
          {
            headers: {
              'Authorization': `token ${githubToken}`,
              'Accept': 'application/vnd.github.v3+json',
              'User-Agent': 'motivBot-LinkIssues'
            }
          }
        );

        if (!reposResponse.ok) {
          console.error(`❌ Failed to fetch repositories page ${page}: ${reposResponse.status}`);

          // Si es la primera página, es un error crítico
          if (page === 1) {
            return res.status(500).json({
              error: 'GitHub API error',
              message: `Failed to fetch repositories from GitHub: ${reposResponse.status}. Check your GITHUB_TOKEN permissions.`
            });
          }

          // Si no es la primera página, puede que hayamos llegado al final
          break;
        }

        const pageRepositories = await reposResponse.json();

        // Si no hay más repositorios, salir del bucle
        if (!pageRepositories || pageRepositories.length === 0) {
          console.log(`📄 No more repositories found on page ${page}`);
          break;
        }

        console.log(`📁 Found ${pageRepositories.length} repositories on page ${page}`);
        allRepositories.push(...pageRepositories);

        // Si recibimos menos repositorios que el máximo, es la última página
        if (pageRepositories.length < perPage) {
          console.log(`📄 Last page reached (${pageRepositories.length} < ${perPage})`);
          break;
        }

        page++;
      }

      console.log(`📁 Total repositories found: ${allRepositories.length} for ${githubUsername}`);

      // También intentar obtener repos donde el usuario es colaborador
      try {
        console.log(`🤝 Fetching repositories where ${githubUsername} is a collaborator...`);

        const collaboratorReposResponse = await fetch(
          `https://api.github.com/user/repos?per_page=100&affiliation=collaborator`,
          {
            headers: {
              'Authorization': `token ${githubToken}`,
              'Accept': 'application/vnd.github.v3+json',
              'User-Agent': 'motivBot-LinkIssues'
            }
          }
        );

        if (collaboratorReposResponse.ok) {
          const collaboratorRepos = await collaboratorReposResponse.json();
          console.log(`🤝 Found ${collaboratorRepos.length} collaborator repositories`);

          // Evitar duplicados comparando por ID
          const existingIds = new Set(allRepositories.map(repo => repo.id));
          const newCollaboratorRepos = collaboratorRepos.filter(repo => !existingIds.has(repo.id));

          if (newCollaboratorRepos.length > 0) {
            console.log(`➕ Adding ${newCollaboratorRepos.length} new collaborator repositories`);
            allRepositories.push(...newCollaboratorRepos);
          }
        } else {
          console.log(`⚠️ Could not fetch collaborator repos: ${collaboratorReposResponse.status}`);
        }
      } catch (collabError) {
        console.log(`⚠️ Error fetching collaborator repos:`, collabError.message);
      }

      const repositories = allRepositories;
      console.log(`📁 Final repository count: ${repositories.length} repositories for processing`);

      if (repositories.length === 0) {
        return res.status(200).json({
          success: true,
          message: 'No repositories found for the user',
          data: {
            github_username: githubUsername,
            total_repositories: 0,
            processed_repositories: 0,
            repositories_with_issues: 0,
            total_issues_found: 0,
            new_tasks_created: 0,
            existing_tasks_found: 0,
            processing_summary: {
              repositories_processed: [],
              new_tasks_by_repo: [],
              repositories_without_issues: []
            },
            issues_summary: []
          }
        });
      }

      let totalNewTasks = 0;
      let totalExistingTasks = 0;
      let processedRepos = 0;
      let repositoriesProcessed = [];

      // Paso 3.2: Iterar por cada repositorio
      for (const [index, repo] of repositories.entries()) {
        try {
          console.log(`🔍 Processing repository ${index + 1}/${repositories.length}: ${repo.full_name}...`);

          // Obtener issues del repositorio (abiertos y cerrados) con paginación
          let allIssues = [];
          let issuePage = 1;
          const issuesPerPage = 100;

          while (true) {
            const issuesResponse = await fetch(
              `https://api.github.com/repos/${repo.full_name}/issues?state=all&per_page=${issuesPerPage}&page=${issuePage}`,
              {
                headers: {
                  'Authorization': `token ${githubToken}`,
                  'Accept': 'application/vnd.github.v3+json',
                  'User-Agent': 'motivBot-LinkIssues'
                }
              }
            );

            if (!issuesResponse.ok) {
              console.error(`❌ Failed to fetch issues from ${repo.full_name}: ${issuesResponse.status}`);
              break;
            }

            const pageIssues = await issuesResponse.json();

            if (!pageIssues || pageIssues.length === 0) {
              break;
            }

            allIssues.push(...pageIssues);

            if (pageIssues.length < issuesPerPage) {
              break;
            }

            issuePage++;
          }

          // Filtrar solo issues (no pull requests)
          const filteredIssues = allIssues.filter(issue => !issue.pull_request);

          console.log(`📝 Found ${filteredIssues.length} issues in ${repo.full_name} (${allIssues.length} total items, ${allIssues.length - filteredIssues.length} pull requests filtered out)`);

          if (filteredIssues.length === 0) {
            console.log(`⏭️  No issues found in ${repo.full_name}, skipping...`);
            continue;
          }

          processedRepos++;
          let repoNewTasks = 0;
          let repoExistingTasks = 0;

          // Paso 3.3: Procesar cada issue del repositorio
          for (const issue of filteredIssues) {
            // Verificar si ya existe una tarea para este issue
            const existingTask = tasks.find(task => {
              // Prioridad 1: Por ID de GitHub issue
              if (task.github_issue_id === issue.id) {
                return true;
              }

              // Prioridad 2: Por título y repo
              if (task.title?.includes(issue.title) && task.github_repo === repo.full_name) {
                return true;
              }

              // Prioridad 3: Verificación por tags array
              if (Array.isArray(task.tags) && task.tags.includes('motivBotLinkIssuesFromGithub')) {
                const taskTitle = task.title?.toLowerCase() || '';
                const issueTitle = issue.title?.toLowerCase() || '';
                if (taskTitle.includes(issueTitle) || issueTitle.includes(taskTitle.replace(/^\[.*?\]\s*/, ''))) {
                  return true;
                }
              }

              return false;
            });

            if (!existingTask) {
              // Determinar prioridad basada en labels
              let priority = 'medium';
              if (issue.labels?.some(label =>
                label.name.toLowerCase().includes('high') ||
                label.name.toLowerCase().includes('urgent') ||
                label.name.toLowerCase().includes('critical')
              )) {
                priority = 'high';
              } else if (issue.labels?.some(label =>
                label.name.toLowerCase().includes('low') ||
                label.name.toLowerCase().includes('minor')
              )) {
                priority = 'low';
              }

              // Crear nueva tarea - cambiar tags a array
              const newTask = {
                title: `[${repo.name}] ${issue.title}`,
                description: `${issue.body || 'No description provided'}\n\n🔗 **GitHub Issue:** ${issue.html_url}\n📁 **Repository:** ${repo.full_name}\n🏷️ **Labels:** ${issue.labels?.map(l => l.name).join(', ') || 'None'}\n👤 **Created by:** ${issue.user?.login || 'Unknown'}`,
                tags: ['motivBotLinkIssuesFromGithub'], // ✅ Cambiar a array
                status: issue.state === 'open' ? 'pending' : 'completed',
                priority: priority,
                github_issue_id: issue.id,
                github_issue_number: issue.number,
                github_repo: repo.full_name,
                github_issue_url: issue.html_url,
                github_issue_state: issue.state,
                created_at: new Date().toISOString(),
                updated_at: new Date().toISOString()
              };

              try {
                const { data: insertedTask, error: insertError } = await supabase
                  .from('task')
                  .insert([newTask])
                  .select();

                if (insertError) {
                  console.error(`❌ Error creating task for issue ${issue.number} in ${repo.full_name}:`, insertError);
                  continue;
                }

                console.log(`✅ Created task for issue #${issue.number} in ${repo.full_name}: ${issue.title}`);
                totalNewTasks++;
                repoNewTasks++;

                issues.push({
                  repo: repo.full_name,
                  issue_number: issue.number,
                  issue_title: issue.title,
                  issue_url: issue.html_url,
                  issue_state: issue.state,
                  task_created: true,
                  task_id: insertedTask[0]?.id,
                  priority: priority
                });

                // Añadir la nueva tarea al array local para evitar duplicados en la misma ejecución
                tasks.push(insertedTask[0]);

              } catch (insertError) {
                console.error(`❌ Error inserting task for issue ${issue.number} in ${repo.full_name}:`, insertError);
              }
            } else {
              console.log(`⏭️  Task already exists for issue #${issue.number} in ${repo.full_name}: ${issue.title}`);
              totalExistingTasks++;
              repoExistingTasks++;

              issues.push({
                repo: repo.full_name,
                issue_number: issue.number,
                issue_title: issue.title,
                issue_url: issue.html_url,
                issue_state: issue.state,
                task_created: false,
                existing_task_id: existingTask.id
              });
            }
          }

          repositoriesProcessed.push({
            name: repo.full_name,
            total_issues: filteredIssues.length,
            new_tasks: repoNewTasks,
            existing_tasks: repoExistingTasks,
            last_updated: repo.updated_at
          });

        } catch (error) {
          console.error(`❌ Error processing repository ${repo.full_name}:`, error);
          continue;
        }
      }

      // Paso 4: Respuesta final con estadísticas detalladas
      console.log(`🎉 Processing completed!`);
      console.log(`📊 Summary: ${totalNewTasks} new tasks created, ${totalExistingTasks} existing tasks found`);

      return res.status(200).json({
        success: true,
        message: 'GitHub issues processed successfully',
        timestamp: new Date().toISOString(),
        data: {
          github_username: githubUsername,
          total_repositories: repositories.length,
          processed_repositories: processedRepos,
          repositories_with_issues: repositoriesProcessed.length,
          total_issues_found: issues.length,
          new_tasks_created: totalNewTasks,
          existing_tasks_found: totalExistingTasks,
          processing_summary: {
            repositories_processed: repositoriesProcessed,
            new_tasks_by_repo: repositoriesProcessed
              .filter(repo => repo.new_tasks > 0)
              .map(repo => ({ name: repo.name, new_tasks: repo.new_tasks })),
            repositories_without_issues: repositories
              .filter(repo => !repositoriesProcessed.find(processed => processed.name === repo.full_name))
              .map(repo => repo.full_name)
          },
          issues_summary: issues
        }
      });

    } catch (error) {
      console.error('❌ Error fetching GitHub data:', error);
      return res.status(500).json({
        error: 'GitHub API error',
        message: `Failed to fetch data from GitHub API: ${error.message}`
      });
    }

  } catch (error) {
    console.error('❌ Internal server error:', error);
    return res.status(500).json({
      error: 'Internal Server Error',
      message: `Environment variables are not set correctly or unexpected error occurred: ${error.message}`
    });
  }
}
