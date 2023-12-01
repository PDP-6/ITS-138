#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static char line[256];
static int spaces;

static void space(void)
{
  while (spaces > 0) {
    putchar(' ');
    spaces--;
  }
}

static void tab(int n)
{
  putchar('\t');
  spaces = n;
}

static void tabify(int column)
{
  while (spaces >= 8)
    tab(spaces - 8);

  if (spaces == 0)
    return;

  if ((column % 8) == 0)
    tab(0);
  else
    space();
}

static void process(void)
{
  int i, n;

  n = strlen(line);
  spaces = 0;
  for (i = 0; i < n; i++) {
    switch (line[i]) {
    case ' ':
      spaces++;		/* Keep tabs (ha ha) of number of spaces seen. */
      break;
    case '\t':
      fprintf(stderr, "Tab in input.\n");
      exit(1);
      break;
    case ';':
      tabify(i);	/* Space before comments is tabified. */
      putchar(';');
      break;
    default:
      if (i == 8)
        tabify(i);	/* Space before instructions is tabified.*/
      else
        space();	/* Other space inside text remains space. */
      putchar(line[i]);
      break;
    }
  }
}

int main(void)
{
  for (;;) {
    if (fgets(line, sizeof line, stdin) == NULL)
      return 0;
    process();
  }
}
