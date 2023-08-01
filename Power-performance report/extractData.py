# EXTRACT DATA
# ----------------------------------------------------------------------------------------------------------------


# START ----
import timer
timer.begin()


# EXECUTION ----
def main():
    data = open('data_2procs.csv', 'w')
    data.write('FPS,Latency,Graph,TotalParts,PartitionPoint1,PartitionPoint2,Order,InferenceTime1,InferenceTime2,'
               'InferenceTime3\n')
    lines = []
    line_new = [''] * 10

    with open('result1.txt', 'r') as RAWDATA:
        for line in RAWDATA:
            if line[0] == '.':
                line_new[2] = line.split('_')[1]
            elif line[:5] == 'First':
                line_new[4] = line[22:-1]
            elif line[:6] == 'Second':
                line_new[5] = line[23:-1]
            elif line[:7] == 'Total p':
                line_new[3] = line[12:-1]
            elif line[:5] == 'Order':
                line_new[6] = line[11:16]
            elif line[:10] == 'stage1_inf':
                line_new[7] = line[23:-4]
            elif line[:10] == 'stage2_inf':
                line_new[8] = line[23:-4]
            elif line[:10] == 'stage3_inf':
                line_new[9] = line[23:-4]
            elif line[6:10] == 'rate':
                line_new[0] = line[15:-5]
            elif line[6:13] == 'latency':
                line_new[1] = line[18:-4]
                lines.append(','.join(line_new))
                line_new = ['']*10

    data.write('\n'.join(lines))
    data.close()

    return


# END ----
if __name__ == '__main__':
    print(main())
    # main()
    # open('output.txt', 'w').write(main())


"""
 


"""
