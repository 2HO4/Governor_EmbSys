# COMMANDS
# ----------------------------------------------------------------------------------------------------------------


# START ----


# EXECUTION ----
def main():

    s = './$1 --threads=4 --threads2=2 --n=40--total_cores=6 --partition_point=$2 --partition_point2=$3 --order='

    n_parts = {
        'graph_alexnet_all_pipe_sync': 8,
        'graph_googlenet_all_pipe_sync': 13,
        'graph_mobilenet_all_pipe_sync': 28,
        'graph_resnet50_all_pipe_sync': 18,
        'graph_squeezenet_all_pipe_sync': 19
    }

    orders = {
        'graph_alexnet_all_pipe_sync': ['8-0-0', '4-2-2', '2-4-2', '2-2-4', '2-3-3', '3-3-2', '3-2-3'],
        'graph_googlenet_all_pipe_sync': ['13-0-0', '7-3-3', '3-7-3', '3-3-7', '4-5-4', '4-4-5', '5-4-4'],
        'graph_mobilenet_all_pipe_sync': ['28-0-0', '14-7-7', '7-14-7', '7-7-14', '4-12-12', '12-12-4', '12-4-12'],
        'graph_resnet50_all_pipe_sync': ['18-0-0', '10-4-4', '4-10-4', '4-4-10', '4-7-7', '7-7-4', '7-4-7'],
        'graph_squeezenet_all_pipe_sync': ['19-0-0', '9-5-5', '5-9-5', '5-5-9', '5-7-7', '7-7-5', '7-5-7']
    }

    orders2 = {cnn: orders_2procs(n_parts[cnn]) for cnn in n_parts}

    pipelines = ['-'.join(tuple(_))
                    for _ in ['GBL', 'GLB', 'BGL', 'BLG', 'LGB', 'LBG']]

    commands = []

    for cnn in n_parts:
        for pipe in pipelines:
            for o in orders2[cnn]:
                p1, p2, p3 = map(int, o.split('-'))
                commands.append(
                    f'./{cnn} --threads=4 --threads2=2 --n=5 --total_cores=6 --partition_point={p1} '
                    f'--partition_point2={p1 + p2} --order={pipe}'
                )

    print(' ; '.join(commands))

    commands_temp = []

    # for o in orders['graph_alexnet_all_pipe_sync']:
    #     p1, p2, p3 = map(int, o.split('-'))
    #     commands_temp.append(
    #         f'./graph_alexnet_all_pipe_sync --threads=4 --threads2=2 --n=10 --total_cores=6 --partition_point={p1} '
    #         f'--partition_point2={p1 + p2} --order=G-B-L'
    #     )
    #
    # print(' ; '.join(commands_temp))

    # print(len(commands))

    return


def orders_2procs(n):
    return tuple(f'{i}-{j}-0' for i, j in zip(range(1, n), range(n - 1, 0, -1)))


# END ----
if __name__ == '__main__':
    print(main())
    # main()
    # open('output.txt', 'w').write(main())


"""
 


"""
