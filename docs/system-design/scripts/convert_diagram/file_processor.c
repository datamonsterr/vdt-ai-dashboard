#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <unistd.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <dirent.h>
#include <errno.h>
#include <time.h>

#define MAX_FILES 1000
#define MAX_PATH_LEN 512
#define MAX_THREADS 16
#define MAX_COMMAND_LEN 1024

// Thread-safe counters
pthread_mutex_t counter_mutex = PTHREAD_MUTEX_INITIALIZER;
int converted_count = 0;
int failed_count = 0;
int processed_count = 0;

// File processing queue
typedef struct {
    char input_path[MAX_PATH_LEN];
    char output_path[MAX_PATH_LEN];
} file_task_t;

typedef struct {
    file_task_t* tasks;
    int task_count;
    int current_task;
    pthread_mutex_t queue_mutex;
    char* chrome_path;
} thread_pool_t;

// Progress tracking
void update_progress(int total) {
    pthread_mutex_lock(&counter_mutex);
    int current_processed = processed_count;
    pthread_mutex_unlock(&counter_mutex);
    
    if (total > 0) {
        int percent = (current_processed * 100) / total;
        printf("\r\033[0;34mProgress: %d%% (%d/%d) | ✅ %d | ❌ %d\033[0m", 
               percent, current_processed, total, converted_count, failed_count);
        fflush(stdout);
    }
}

// Worker thread function
void* worker_thread(void* arg) {
    thread_pool_t* pool = (thread_pool_t*)arg;
    file_task_t task;
    char command[MAX_COMMAND_LEN];
    
    while (1) {
        // Get next task from queue
        pthread_mutex_lock(&pool->queue_mutex);
        if (pool->current_task >= pool->task_count) {
            pthread_mutex_unlock(&pool->queue_mutex);
            break;
        }
        task = pool->tasks[pool->current_task++];
        pthread_mutex_unlock(&pool->queue_mutex);
        
        // Build conversion command
        if (pool->chrome_path && strlen(pool->chrome_path) > 0) {
            snprintf(command, sizeof(command),
                "PUPPETEER_EXECUTABLE_PATH='%s' timeout 30s mmdc -i '%s' -o '%s' -t dark -b transparent >/dev/null 2>&1",
                pool->chrome_path, task.input_path, task.output_path);
        } else {
            snprintf(command, sizeof(command),
                "timeout 30s mmdc -i '%s' -o '%s' -t dark -b transparent >/dev/null 2>&1",
                task.input_path, task.output_path);
        }
        
        // Execute conversion
        int result = system(command);
        
        // Update counters thread-safely
        pthread_mutex_lock(&counter_mutex);
        if (result == 0) {
            converted_count++;
        } else {
            failed_count++;
        }
        processed_count++;
        pthread_mutex_unlock(&counter_mutex);
    }
    
    return NULL;
}

// Fast directory scanning for .mmd files
int scan_mmd_files(const char* diagrams_dir, file_task_t* tasks, int max_tasks, const char* output_dir) {
    DIR* dir;
    struct dirent* entry;
    int task_count = 0;
    
    dir = opendir(diagrams_dir);
    if (!dir) {
        fprintf(stderr, "Error opening directory: %s\n", diagrams_dir);
        return -1;
    }
    
    while ((entry = readdir(dir)) != NULL && task_count < max_tasks) {
        int len = strlen(entry->d_name);
        if (len > 4 && strcmp(entry->d_name + len - 4, ".mmd") == 0) {
            // Build input path
            snprintf(tasks[task_count].input_path, MAX_PATH_LEN, 
                    "%s/%s", diagrams_dir, entry->d_name);
            
            // Build output path (replace .mmd with .png)
            char basename[MAX_PATH_LEN];
            strncpy(basename, entry->d_name, len - 4);
            basename[len - 4] = '\0';
            snprintf(tasks[task_count].output_path, MAX_PATH_LEN,
                    "%s/%s.png", output_dir, basename);
            
            task_count++;
        }
    }
    
    closedir(dir);
    return task_count;
}

// High-performance parallel processing
int process_files_parallel(const char* diagrams_dir, const char* output_dir, 
                          const char* chrome_path, int num_threads) {
    file_task_t tasks[MAX_FILES];
    pthread_t threads[MAX_THREADS];
    thread_pool_t pool;
    
    // Scan for .mmd files
    printf("\033[0;33mScanning for .mmd files...\033[0m\n");
    int task_count = scan_mmd_files(diagrams_dir, tasks, MAX_FILES, output_dir);
    if (task_count <= 0) {
        printf("No .mmd files found or error scanning directory.\n");
        return task_count < 0 ? 1 : 0;
    }
    
    printf("\033[0;34m📊 Found %d diagram files to convert\033[0m\n", task_count);
    printf("\033[0;34m🔧 Using %d concurrent threads\033[0m\n", num_threads);
    
    // Initialize thread pool
    pool.tasks = tasks;
    pool.task_count = task_count;
    pool.current_task = 0;
    pool.chrome_path = (char*)chrome_path;
    pthread_mutex_init(&pool.queue_mutex, NULL);
    
    // Record start time
    clock_t start_time = clock();
    
    // Create worker threads
    printf("\n\033[0;33mStarting parallel conversion...\033[0m\n");
    for (int i = 0; i < num_threads; i++) {
        if (pthread_create(&threads[i], NULL, worker_thread, &pool) != 0) {
            fprintf(stderr, "Error creating thread %d\n", i);
            return 1;
        }
    }
    
    // Monitor progress
    while (processed_count < task_count) {
        update_progress(task_count);
        usleep(200000); // 200ms
    }
    
    // Wait for all threads to complete
    for (int i = 0; i < num_threads; i++) {
        pthread_join(threads[i], NULL);
    }
    
    // Final progress update
    update_progress(task_count);
    printf("\n");
    
    // Calculate performance metrics
    clock_t end_time = clock();
    double duration = ((double)(end_time - start_time)) / CLOCKS_PER_SEC;
    
    // Performance summary
    printf("\n\033[0;32m🎉 Conversion complete!\033[0m\n");
    printf("\033[0;34m📈 Performance Summary:\033[0m\n");
    printf("   ⏱️  Duration: \033[0;34m%.2fs\033[0m\n", duration);
    printf("   ✅ Successfully converted: \033[0;32m%d\033[0m diagrams\n", converted_count);
    
    if (converted_count > 0 && duration > 0) {
        double throughput = (converted_count * 60.0) / duration;
        printf("   🚀 Throughput: \033[0;34m~%.1f diagrams/minute\033[0m\n", throughput);
    }
    
    if (failed_count > 0) {
        printf("   ❌ Failed conversions: \033[0;31m%d\033[0m diagrams\n", failed_count);
    }
    
    // Cleanup
    pthread_mutex_destroy(&pool.queue_mutex);
    pthread_mutex_destroy(&counter_mutex);
    
    return (converted_count == 0 && failed_count > 0) ? 1 : 0;
}

int main(int argc, char* argv[]) {
    if (argc < 3) {
        fprintf(stderr, "Usage: %s <diagrams_dir> <output_dir> [chrome_path] [num_threads]\n", argv[0]);
        return 1;
    }
    
    const char* diagrams_dir = argv[1];
    const char* output_dir = argv[2];
    const char* chrome_path = (argc > 3) ? argv[3] : "";
    int num_threads = (argc > 4) ? atoi(argv[4]) : sysconf(_SC_NPROCESSORS_ONLN);
    
    // Ensure reasonable thread count
    if (num_threads <= 0 || num_threads > MAX_THREADS) {
        num_threads = sysconf(_SC_NPROCESSORS_ONLN);
        if (num_threads <= 0) num_threads = 4;
    }
    
    printf("\033[0;34m🚀 Starting C-optimized Mermaid diagram conversion\033[0m\n");
    
    return process_files_parallel(diagrams_dir, output_dir, chrome_path, num_threads);
}
