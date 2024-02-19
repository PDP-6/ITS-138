#include <time.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <signal.h>
#include <stdlib.h>
#include <stdatomic.h>
#include <sys/mman.h>
#include <sys/types.h>

typedef struct {
  volatile pid_t pdp10_pid;
  atomic_uint_fast8_t pdp10_command;
  atomic_uint_fast32_t pdp10_address;
  atomic_uint_fast16_t pdp10_data;

  volatile pid_t pdp11_pid;
  atomic_uint_fast8_t pdp11_status;
  atomic_uint_fast32_t pdp11_address;
  atomic_uint_fast16_t pdp11_data;

  volatile char pdp11_core[128*1024];

  atomic_uint_fast16_t memory[128*1024];
} shared_memory_t;

#define MEM_CHECK   1
#define MEM_READ    2
#define MEM_WRITE   3

static pid_t parent_pid, child_pid;
static long long parent_roundtrips;
static shared_memory_t *mem;

static void fatal(const char *message)
{
  fprintf(stderr, "Error: %s\n", message);
  exit(1);
}

static void map(void)
{
  int fd = open("memory", O_RDWR);
  if (fd == -1)
    fatal("open");
  if (ftruncate(fd, sizeof(shared_memory_t)) == -1)
    fatal("trunc");
  mem = mmap(NULL, sizeof(shared_memory_t),
             PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
  if (mem == NULL)
    fatal("mmap");
}

void parent(void)
{
  struct timespec ts1, ts2;
  double seconds;
  sigset_t set;
  int sig;

  map();
  mem->pdp10_pid = getpid();

  sleep(1);
  sigemptyset(&set);
  sigaddset(&set, SIGUSR2);
  sigprocmask(SIG_BLOCK, &set, NULL);

  clock_gettime(CLOCK_REALTIME, &ts1);
  for(;;) {
    atomic_store(&mem->pdp10_command, MEM_WRITE);
    atomic_store(&mem->pdp10_address, 001234);
    atomic_store(&mem->pdp10_data, 01234567);
    if (kill(mem->pdp11_pid, SIGUSR1) == -1)
      fatal("kill");
    if (sigwait(&set, &sig) != 0)
      fprintf(stderr, "Error\n");
    parent_roundtrips++;
    if(parent_roundtrips == 1000000) {
      clock_gettime(CLOCK_REALTIME, &ts2);
      seconds = ts2.tv_sec - ts1.tv_sec;
      seconds += (ts2.tv_nsec - ts1.tv_nsec) * 1e-9;
      printf("%f\n", parent_roundtrips / seconds);
      parent_roundtrips = 0;
      ts1 = ts2;
    }
  }
}

void handle_usr1(int sig)
{
  (void)sig;
  atomic_store(&mem->memory[mem->pdp10_address], mem->pdp10_data);
  if (kill(mem->pdp10_pid, SIGUSR2) == -1)
    fatal("kill");
}

void child(void)
{
  map();
  mem->pdp11_pid = getpid();

#if 1
  signal(SIGUSR1, handle_usr1);
#else
  sigset_t set;
  int sig;
  sigemptyset(&set);
  sigaddset(&set, SIGUSR1);
  sigprocmask(SIG_BLOCK, &set, NULL);
#endif

  for(;;) {
#if 1
    ;
#else
    if (sigwait(&set, &sig) != 0)
      fprintf(stderr, "Error\n");
    handle_usr1(sig);
#endif
  }
}

int main(void)
{
  parent_pid = getpid();
  child_pid = fork();
  if(child_pid)
    parent();
  else
    child();
}
