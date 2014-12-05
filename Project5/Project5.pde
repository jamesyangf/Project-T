Block[][] blocks;
Player player;
ArrayList<ParticleSystem> systems;

//blocks available in inventory
ArrayList<Block> inventory;
HashMap<String, Integer> blockCount;
float index;

int blockLength;
float playerHeight;
int playerWidth;
PImage background;

PVector loc;
PVector vel;
PVector gravity;
boolean mouse1, mouse2, devMode;

Table map;

int gameScreen;

void setup() {
  size(1000, 600);
  blockLength = 20;
  playerHeight = 1.8 * blockLength;
  playerWidth = blockLength;
  blocks = new Block[height / blockLength][width / blockLength]; 
  background = loadImage("data/background.png");
  background.resize(width, height);

  gameScreen = 0; //menu screen
  index = 0; //variable for selected block in inventory

  //inventory arraylist
  inventory = new ArrayList();
  inventory.add(new Block("grass", 2));
  inventory.add(new Block("dirt", 2));
  inventory.add(new Block("cobble", 2));
  inventory.add(new Block("wood", 2));
  inventory.add(new Block("leaf", 2));
  inventory.add(new Block("plank", 2));

  //inventory count
  blockCount = new HashMap<String, Integer>();
  for (Block b : inventory)
  {
    blockCount.put(b.getType(), 0);
  }

  player = new Player(new PVector(width/2, 0), new PVector(playerWidth, playerHeight));

  mouse1 = mouse2 = false;
  devMode = true;
  gameScreen = 3; //set it to ingame screen

  map = loadTable("input.csv", "header");

  for (TableRow row : map.rows ()) {
    if (row.getString("block") != null) blocks[row.getInt("y")][row.getInt("x")] = new Block(row.getString("block"));
  }

  systems = new ArrayList<ParticleSystem>();
}

void draw()
{
  if (gameScreen == 3)
  {
    image(background, 0, 0);
  
    //draw the terrain
    player.update();
    player.draw();
  
    //block placement/destroy
    if (devMode || distanceTo(mouseX, mouseY, player.getLocation().x + playerWidth / 2, player.getLocation().y + playerHeight / 2) < blockLength * 5) {
      if (mouse1)
      {
        //place blocks, but make sure that they aren't placed on the character
        PVector location = player.getLocation();
        PVector hitbox = player.getHitbox();
        int i0 = (int)location.x/blockLength;
        int i1 = (int)(location.x+hitbox.x-1)/blockLength;
        int j0 = (int)location.y/blockLength;
        int j1 = (int)(location.y + hitbox.y/2-1)/blockLength;
        int j2 = (int)(location.y + hitbox.y-1)/blockLength;
        int mx = (int)mouseX/blockLength;
        int my = (int)mouseY/blockLength;
        boolean flag =  ((i0 == mx && (my == j0 || my == j1 || my == j2)) || (i1 == mx && (my == j0 || my == j1 || my == j2)));
        flag = flag || (my < 0 || my >= blocks.length || mx < 0 || mx >= blocks[0].length);
        if (!flag) flag = blocks[my][mx] != null;
        String type = inventory.get((int)index).getType();
        if (!flag && ((int)blockCount.get(type) != 0 || devMode)) 
        {
          PVector loc = player.getLocation();
          blocks[my][mx] = new Block(type);
          if (!devMode) blockCount.put(type, (int)blockCount.get(type)-1);
        }
      } else if (mouse2)
      {
        int mx = (int)mouseX/blockLength;
        int my = (int)mouseY/blockLength;
        boolean flag = (my < 0 || my >= blocks.length || mx < 0 || mx >= blocks[0].length);
        if (!flag) flag = flag || blocks[my][mx] == null;
        if (!flag)
        {
          PVector loc = player.getLocation();
          systems.add(new ParticleSystem(10, new PVector(mx*blockLength, my*blockLength), blocks[my][mx].getTexture()));
          if (!devMode) blockCount.put(blocks[my][mx].getType(), (int)blockCount.get(blocks[my][mx].getType())+1);
          blocks[my][mx] = null;
        }
      }
    }
    //render block destroy particles
    for (int i = systems.size ()-1; i >= 0; i--)
    {
      ParticleSystem s = systems.get(i);
      s.update();
      if (s.isDead())
      {
        systems.remove(s);
      }
    }
  
    //render blocks
    for (int i = 0; i < blocks.length; i++) {
      for (int j = 0; j < blocks[0].length; j++) {
        if (blocks[i][j] != null) image(blocks[i][j].texture, j * blockLength, i * blockLength);
      }
    }
  
    //draw the inventory
    drawInventory();
  
    if (devMode) {
      stroke(255, 0, 0);
      noFill();
      rect(0, 0, width -1, height -1);
      noStroke();
    }
  }
}

float distanceTo(float x1, float y1, float x2, float y2) {
  return sqrt(pow(x1 - x2, 2) + pow(y1 - y2, 2));
}

void keyPressed() {
  if (gameScreen == 3)
  {
    if (key == 'a') {
      player.setHSpeed(-2);
      player.facingLeft = true;
    } else if (key == 'd') {
      player.setHSpeed(2);
      player.facingLeft = false;
    }
    if (key == '`') devMode = !devMode;
    if (key == BACKSPACE) saveMap();
    if (key == 'w')
    {
      PVector location = player.getLocation();
      PVector hitbox = player.getHitbox();
      int i0 = (int)location.x/blockLength;
      int i1 = (int)(location.x+hitbox.x-1)/blockLength;
      int j2 = (int)(location.y + hitbox.y)/blockLength;
      if (j2 >= blocks.length || blocks[j2][i0] != null || blocks[j2][i1] != null)
      {
        player.setVSpeed(-7);
      }
    }
    if (key == CODED) {
      if (keyCode == LEFT) {
        index -= 1;
        if (index < 0) index += 5;
        index %= inventory.size();
      } else if (keyCode == RIGHT) {
        index += 1;
        index %= inventory.size();
      } else if (keyCode == CONTROL && devMode) {
        player.setVelocity(new PVector());
        if ((int)mouseY/blockLength == 29) {
          if (blocks[29][(int)mouseX/blockLength] == null && blocks[28][(int)mouseX/blockLength] == null) {
            player.setLocation(new PVector((int)mouseX/blockLength * blockLength, 28.2 * blockLength));
          }
        } else if (blocks[(int)mouseY/blockLength][(int)mouseX/blockLength] == null && blocks[(int)mouseY/blockLength + 1][(int)mouseX/blockLength] == null) {
          player.setLocation(new PVector((int)mouseX/blockLength * blockLength, mouseY/blockLength * blockLength + blockLength*.2));
        } else if ((int)mouseY/blockLength == 0) {
          if (blocks[0][(int)mouseX/blockLength] == null && blocks[1][(int)mouseX/blockLength] == null) {
            player.setLocation(new PVector((int)mouseX/blockLength * blockLength, mouseY/blockLength * blockLength + blockLength*.2));
          }
        } else if (blocks[(int)mouseY/blockLength][(int)mouseX/blockLength] == null && blocks[(int)mouseY/blockLength + 1][(int)mouseX/blockLength] != null && blocks[(int)mouseY/blockLength - 1][(int)mouseX/blockLength] == null) {
           player.setLocation(new PVector((int)mouseX/blockLength * blockLength, (mouseY/blockLength - 1) * blockLength + blockLength*.2));
        }
      }
    }
  }
}

void saveMap() {
  String temp = "y,x,block ";
  for (int i = 0; i < blocks.length; i++) {
    for (int j = 0; j < blocks[0].length; j++) {
      if (blocks[i][j] != null) {
        temp += (i + "," + j + "," + blocks[i][j].type + " ");
      }
    }
  }
  temp = temp.substring(0, temp.length() - 1);
  String[] list = split(temp, ' ');
  saveStrings("data/input.csv", list);
}

void keyReleased() {
  if (gameScreen == 3)
  {
  if (key == 'a' || key == 'd')
    {
      player.setHSpeed(0);
    }
  }
}

void mousePressed() {
  if (mouseButton == LEFT) mouse1 = true;
  else if (mouseButton == RIGHT) mouse2 = true;
}

void mouseReleased() {
  if (mouseButton == LEFT) mouse1 = false;
  else if (mouseButton == RIGHT) mouse2 = false;
}

void mouseWheel(MouseEvent e)
{
  if (gameScreen == 3)
  {
    float count = e.getCount();
    float change = count/2;
    index += change;
    if (index < 0) index += 5;
    index %= inventory.size();
  }
}

void drawInventory()
{
  fill(50, 0, 200, 128);
  noStroke();
  rect(blockLength/2, blockLength/2, 2.2*blockLength*inventory.size() + 0.2*blockLength, 2.4*blockLength+16);
  fill(255, 75);
  rect(blockLength/2 + 2.2*blockLength*(int)index, blockLength/2, 2.4*blockLength, 2.4*blockLength);
  fill(255);
  textSize(10);
  for (int i = 0; i < inventory.size (); i++)
  {
    float x = blockLength/2 + 2.2*blockLength*i + 0.2*blockLength;
    float y = blockLength/2 + 0.2*blockLength;
    image(inventory.get(i).texture, x, y);
    if (blockCount.get(inventory.get(i).getType()) == 0)
    {
      fill(0, 128);
      rect(x, y, inventory.get(i).texture.width, inventory.get(i).texture.height);
      fill(255, 128);
    } else
    {
      fill(255);
    }
    text(blockCount.get(inventory.get(i).getType()), x, y + 2.4*blockLength + 6);
  }
}

