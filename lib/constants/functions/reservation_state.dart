String getStateName(int state) {
  switch (state) {
    case 0:
      return "Nem érkezett még meg";
    case 1:
      return "Beérkezett";
    case 2:
      return "Idő túllépés";
    case 3:
      return "Elment";
    case 4:
      return "Foglalás lemondva";
    default:
      return "Ismeretlen";
  }
}
