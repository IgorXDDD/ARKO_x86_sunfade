#include <sys/stat.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

void sunfade(void* img, int width, int height ,int dist, int x,int y );





/*24.void sunfade(void *img, int width, int height, int dist, int x, inty);
Rozjaśnienie obrazu od zadanego punktu.
 Kolor każdego piksel powinien zostać zinterpolowany liniowo pomiędzy
  kolorem oryginalnym i bielą proporcjonalnie do kwadratu odległości 
  piksela od piksela o współrzędnych x,y. Piksele położone dalej od 
  krawędzi niż wartość dist nie podlegają modyfikacji.*/
//program dziala dla 24bpp bitmap
int main (int argc, char** argv) 
{

    char* buff;

    if (argc != 5 ) 
    {
        puts("Za malo argumentow!");
        printf("Tak to powinno wygladac: %s [obraz.bmp] [promien] [x] [y]\n",argv[0]);
        return 1;
    }

    struct stat st;
    stat(argv[1], &st);

    buff = (char *) malloc(st.st_size);
    if (buff == NULL) 
    {
        printf("Memory error!!\n");
        return 1;
    }

    int fd = open(argv[1], O_RDONLY, 0);
    if (fd == -1)
    {
        printf("File access error\n");
        free(buff);
        return 1;
    }

    //czytanie informacji o bitmapie
    int size = read(fd, buff, st.st_size);
    uint32_t offset    = *(uint32_t *) (buff + 0x0a);
    uint32_t width    = *(uint32_t *) (buff + 0x12);
    uint32_t height    = *(uint32_t *) (buff + 0x16);
    uint16_t bpp    = *(uint16_t *) (buff + 0x1c);

    if (bpp == 24) 
    {
        int fd_out;
        // do porcedury wrzucamy adres od pierwszych pixeli, z pominieciem bajtow informacyjnych
        sunfade(buff + offset, width , height , atoi(argv[2]), atoi(argv[3]), atoi(argv[4]) );
        fd_out = creat("fade.bmp", 0644);
        write(fd_out, buff, size);
        close(fd_out);
        printf("Sunfading Complete.\n");
    }
    else 
    {
        printf("Invalid BMP\n");
    }

    close(fd);
    free(buff);

    return 0;
}
