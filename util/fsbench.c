#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <string.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

/*
 * WARNING: DO NOT RUN THIS ON YOUR MAIN MACHINE.
 * Compile with:
 * $ cc -o fsbench -lpthread -O2 -x fsbench.c
 */

#define MAX_THREAD_COUNT 128

// NOT CHECKED. MAKE SURE THE FILE NAME LENGHT
// DOESN'T GO OVER THIS NUMBER OF SYMBOLS.
#define MAX_NAME_LENGTH 256
// set to something unique
#define SIGNATURE "WE-RAN-HERE-B4_614e2ab3"

void *
print_things(void *arg)
{
	unsigned int tn = *(unsigned int *)arg;
	(void)printf("hello from thread %u\n", tn);
	return 0;
}

void *
spawn_dirs(void *arg)
{
	unsigned int tn = *(unsigned int *)arg;
	unsigned int counter;
	char dir_name[MAX_NAME_LENGTH];
	int ret_val;

	counter = 1;
	while (1)
	{
		(void)sprintf(dir_name, "%u_%u", tn, counter);
		if (mkdir(dir_name, 0700) < 0)
		{
			(void)fprintf(stderr, "thread %u: failed to create directory: %s\n",
						  tn, dir_name);
			return (void *)(intptr_t)1;
		}
		counter++;
	}
	return (void *)(intptr_t)0;
}

void *
spawn_files(void *arg)
{
	unsigned int tn = *(unsigned int *)arg;
	unsigned int counter;
	char file_name[MAX_NAME_LENGTH];
	int fd;

	counter = 1;
	while (1)
	{
		(void)sprintf(file_name, "%u_%u", tn, counter);

		fd = open(file_name, O_WRONLY | O_CREAT | O_TRUNC, 0600);
		if (fd < 0)
		{
			(void)fprintf(stderr, "thread %u: failed to create file: %s\n",
						  tn, file_name);
			return (void *)(intptr_t)1;
		}
		close(fd);

		counter++;
	}
	return (void *)(intptr_t)0;
}

void *
spawn_symlinks(void *arg)
{
	unsigned int tn = *(unsigned int *)arg;
	unsigned int counter;
	char symlink_name[MAX_NAME_LENGTH];
	int ret_val;

	counter = 1;
	while (1)
	{
		(void)sprintf(symlink_name, "%u_%u", tn, counter);
		if (symlink(SIGNATURE, symlink_name) < 0)
		{
			(void)fprintf(stderr, "thread %u: failed to create symlink: %s => %s\n",
						  tn, symlink_name, SIGNATURE);
			return (void *)(intptr_t)1;
		}
		counter++;
	}
	return (void *)(intptr_t)0;
}

static void
print_usage(const char *progname)
{
	(void)fprintf(stderr, "usage: %s [threads] {file / dir / symlink / print}\n", progname);
	exit(1);
}

int
main(const int argc, const char *argv[])
{
	const char *progname = argv[0];

	/*
	 * 1 - file
	 * 2 - dir
	 * 3 - symlink
	 * 4 - print
	 */
	unsigned int op_type = 0;
	unsigned int thread_count;
	int fd;

	switch (argc)
	{
		case 2:
			op_type = 2;
			break;
		case 3:
			if (!strcmp(argv[2], "file"))
			{
				op_type = 1;
			}
			else if (!strcmp(argv[2], "dir"))
			{
				op_type = 2;
			}
			else if (!strcmp(argv[2], "symlink"))
			{
				op_type = 3;
			}
			else if (!strcmp(argv[2], "print"))
			{
				op_type = 4;
			}
			break;
		default:
			print_usage(progname);
	}

	thread_count = (unsigned int)atoi(argv[1]);

	if (thread_count > MAX_THREAD_COUNT)
	{
		(void)fprintf(stderr, "%s: too many threads specified: %u (max: %i)\n",
					  argv[0], thread_count, MAX_THREAD_COUNT);
		exit(1);
	}

	pthread_t threads[thread_count];
	unsigned int thread_args[thread_count];
	unsigned int counter;
	unsigned short failed_counter;
	int retval;
	struct stat st = {0};

	/*
	 * checks so we don't run this in a single directory twice
	 */
	if (stat(SIGNATURE, &st) != -1)
	{
		(void)fprintf(stderr, "%s: signature file %s already exists, not running twice in the same directory\n",
					  progname, SIGNATURE);
		exit(1);
	}

	fd = open(SIGNATURE, O_WRONLY | O_CREAT | O_TRUNC, 0600);
	if (fd < 0)
	{
		(void)fprintf(stderr, "%s: failed to create signature file %s\n", progname, SIGNATURE);
		exit(1);
	}
	close(fd);

	/*
	 * launch all the threads here and count how many failed
	 */
	failed_counter = 0;
	for (counter = 0; counter < thread_count; counter++)
	{
		/*
		 * if more than half of the threads failed, we bail out
		 */
		thread_args[counter] = counter + 1;
		if (failed_counter > (thread_count / 2))
		{
			(void)fprintf(stderr, "%s: too many failed threads\n", progname);
			exit(1);
		}

		/*
		 * switch case with all the optypes
		 */
		switch (op_type)
		{
			case 1:
				(void)fprintf(stderr, "STARTING THREAD %u | FILES\n", counter + 1);
				retval = pthread_create(&threads[counter], NULL, spawn_files, &thread_args[counter]);
				break;
			case 2:
				(void)fprintf(stderr, "STARTING THREAD %u | DIRECTORIES\n", counter + 1);
				retval = pthread_create(&threads[counter], NULL, spawn_dirs, &thread_args[counter]);
				break;
			case 3:
				(void)fprintf(stderr, "STARTING THREAD %u | SYMLINKS\n", counter + 1);
				retval = pthread_create(&threads[counter], NULL, spawn_symlinks, &thread_args[counter]);
				break;
			case 4:
				(void)fprintf(stderr, "STARTING THREAD %u | PRINTING\n", counter + 1);
				retval = pthread_create(&threads[counter], NULL, print_things, &thread_args[counter]);
				break;
			default:
				(void)fprintf(stderr, "%s: invalid operation type\n", progname);
				exit(1);
		}

		if (retval)
		{
			(void)fprintf(stderr, "%s: !! thread %u failed to launch !!\n",
					progname, counter + 1);
			failed_counter++;
		}
	}

	for (counter = 0; counter < thread_count; counter++) {
		if (pthread_join(threads[counter], NULL))
		{
			(void)fprintf(stderr, "%s: thread %u died\n", progname, counter);
		}
	}

	return 0;
}
