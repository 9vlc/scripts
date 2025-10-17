#if 0 == 1 /* compile by running this as a shell script */
cc -o fstress -O3 -lpthread -Wall -Werror -pedantic "$0"; exit
#endif

#define MAX_NAME_LENGTH 22 /* uint32_t + uint32_t + _ + \0 */
#define RUN_LENGTH 1000000
#define THREAD_COUNT 10

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <sys/random.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <sys/types.h>
#include <unistd.h>
#include <pthread.h>
#include <fcntl.h>

typedef struct {
	uint32_t id;
	uint32_t start;
	uint32_t end;
} thread_args_t;

void *
s_files(void *arg)
{
	thread_args_t *a = (thread_args_t *)arg;	
	char name[MAX_NAME_LENGTH] = {0};
	uint32_t c;
	int fd;

	for (c = a->start; c < a->end; c++)
	{
		sprintf(name, "%010u_%010u", c, arc4random());
		fd = open(name, O_WRONLY | O_CREAT, 0600);
		if (fd < 0)
		{
			perror("open");
			return (void *)(intptr_t)1;
		}
		close(fd);
	}
	
	return NULL;
}

void *
s_dirs(void *arg)
{
	thread_args_t *a = (thread_args_t *)arg;	
	char name[MAX_NAME_LENGTH] = {0};
	uint32_t c;

	for (c = a->start; c < a->end; c++)
	{
		sprintf(name, "%010u_%010u", c, arc4random());
		if (mkdir(name, 0700) < 0)
		{
			perror("mkdir");
			return (void *)(intptr_t)1;
		}
	}
	return NULL;
}

void *
s_links(void *arg)
{
	thread_args_t *a = (thread_args_t *)arg;	
	char l_src[MAX_NAME_LENGTH] = "/usr/bin/awk";
	char l_dest[MAX_NAME_LENGTH] = {0};
	uint32_t c;

	for (c = a->start; c < a->end; c++)
	{
		sprintf(l_dest, "%010u_%010u", c, arc4random());
		if (symlink(l_src, l_dest) < 0)
		{
			perror("symlink");
			return (void *)(intptr_t)1;
		}
		(void)memcpy(l_src, l_dest, MAX_NAME_LENGTH);
	}
	
	return NULL;
}

/*
 * the only one here that's not a pthread
 */
void
s_dirs_nest(uint32_t start, uint32_t end)
{
	char name[MAX_NAME_LENGTH] = {0};
	uint32_t c;

	for (c = start; c < end; c++)
	{
		sprintf(name, "%010u_%010u", c, arc4random());
		if (mkdir(name, 0700) < 0)
		{
			perror("mkdir");
			_exit(EXIT_FAILURE);
		}
		else if (chdir(name) < 0)
		{
			perror("chdir");
			_exit(EXIT_FAILURE);
		}
	}
}

void
usage(const char *name)
{
	fprintf(stderr,
		"usage: %s testname\n"
		"available stress tests: "
		"file dir dirnest link\n", name
	);
	exit(EXIT_FAILURE);
}

int
main(const int argc, const char **argv)
{
	uint32_t i, dirnest, chunk, rem, ret, start, end;
	void *(*tfptr)(void *);

	if (argc < 2)
		usage(argv[0]);

	dirnest = 0;
	tfptr = NULL;
	if (!strcmp(argv[1], "file"))
		tfptr = &s_files;
	else if (!strcmp(argv[1], "dir"))
		tfptr = &s_dirs;
	else if (!strcmp(argv[1], "link"))
		tfptr = &s_links;
	else if (!strcmp(argv[1], "dirnest"))
		dirnest = 1;
	else
		usage(argv[0]);
	
	pid_t pids[THREAD_COUNT];
	pid_t pid;
	pthread_t threads[THREAD_COUNT];
	thread_args_t thread_args[THREAD_COUNT];

	chunk = RUN_LENGTH / THREAD_COUNT;
	rem = RUN_LENGTH % THREAD_COUNT;
	for (i = 0; i < THREAD_COUNT; i++)
	{
		start = i * chunk + (i < rem ? i : rem);
		end = start + chunk + (i < rem ? 1 : 0);

		if (dirnest)
		{
			pid = fork();
			if (pid < 0)
				perror("fork");
			else if (pid == 0)
			{
				s_dirs_nest(start, end);
				_exit(EXIT_SUCCESS);
			}
			pids[i] = pid;
		}
		else
		{
			thread_args[i].id = i;
			thread_args[i].start = start;
			thread_args[i].end = end;
		
			ret = pthread_create(&threads[i], NULL, tfptr, &thread_args[i]);
			if (ret != 0)
			{
				fprintf(stderr, "pthread_create: %s\n", strerror(ret));
				exit(EXIT_FAILURE);
			}
		}
	}

	for (i = 0; i < THREAD_COUNT; i++)
	{
		if (dirnest)
		{
			waitpid(pids[i], NULL, 0);
		}
		else
		{
			ret = pthread_join(threads[i], NULL);
			if (ret != 0)
			{
				fprintf(stderr, "pthread_join: %s\n", strerror(ret));
				exit(EXIT_FAILURE);
			}
		}
	}

	return 0;
}
