int main(int argc, char **argv) {
  int *array = new int[100];
  int res = array[argc + 100];  // BOOM
  delete [] array;
  return res;
}
