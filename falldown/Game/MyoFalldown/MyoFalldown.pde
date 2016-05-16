 //================================================================================================================
// MyoFalldown
// Author: David Hanna
//
// Top-level game loop of Myo Falldown.
//================================================================================================================

// Includes are available project-wide, so they are collected here.
import java.util.ArrayList;
import java.util.LinkedList;
import java.util.Map;

import org.jbox2d.common.*;
import org.jbox2d.dynamics.*;
import org.jbox2d.dynamics.contacts.Contact;
import org.jbox2d.collision.*;
import org.jbox2d.collision.shapes.*;
import org.jbox2d.callbacks.ContactListener;
import org.jbox2d.callbacks.ContactImpulse;

import sprites.utils.*;
import sprites.maths.*;
import sprites.*;

import de.voidplus.myo.*;

import processing.sound.SoundFile;

// The main class needs to be available globally for some subsystems.
MyoFalldown mainObject;

// The Event system.
IEventManager eventManager;

// Physics
Vec2 gravity;
World physicsWorld;
FalldownContactListener contactListener;
int velocityIterations;    // Fewer iterations increases performance but accuracy suffers.
int positionIterations;    // More iterations decreases performance but improves accuracy.
                           // Box2D recommends 8 for velocity and 3 for position.

// The controller for the current game state (i.e. main menu, in-game, etc)
IGameStateController gameStateController;

// Handles EMG input
IEmgManager emgManager;

// Top-level game loop variables.
int lastFrameTime;

final String LEFT_DIRECTION_LABEL = "LEFT";
final String RIGHT_DIRECTION_LABEL = "RIGHT";
final String JUMP_DIRECTION_LABEL = "JUMP";

// The Options menu object, contains methods to alter sub menus
OptionsObject optionsMenu;

void setup()
{
  size(500, 500);
  surface.setResizable(true);
  
  rectMode(CENTER);
  ellipseMode(CENTER);
  imageMode(CENTER);
  shapeMode(CENTER);
  
  mainObject = this;
  
  eventManager = new EventManager();
  
  gravity = new Vec2(0.0, 10.0);
  physicsWorld = new World(gravity); // gravity
  contactListener = new FalldownContactListener();
  physicsWorld.setContactListener(contactListener);
  velocityIterations = 6;  // Our simple games probably don't need as much iteration.
  positionIterations = 2;
  
  gameStateController = new GameStateController();
  gameStateController.pushState(new GameState_MainMenu());

  emgManager = new NullEmgManager();
  
  lastFrameTime = millis();

  optionsMenu = new OptionsObject();
} 

void draw()
{
  int currentFrameTime = millis();
  int deltaTime = currentFrameTime - lastFrameTime;
  lastFrameTime = currentFrameTime;
  
  scale(width / 500.0, height / 500.0);
  background(255, 255, 255);
  
  // Solves debugger time distortion, or if something goes wrong and the game freezes for a moment before continuing.
  if (deltaTime > 100)
  {
    deltaTime = 16;
  }
  
  eventManager.update();
  gameStateController.update(deltaTime);
}

void keyPressed()
{
  Event event;
  
  if (key == CODED)
  {
    switch (keyCode)
    {
      case UP:
        event = new Event(EventType.UP_BUTTON_PRESSED);
        eventManager.queueEvent(event);
        return;
        
      case LEFT:
        event = new Event(EventType.LEFT_BUTTON_PRESSED);
        eventManager.queueEvent(event);
        return;
        
      case RIGHT:
        event = new Event(EventType.RIGHT_BUTTON_PRESSED);
        eventManager.queueEvent(event); 
        return;
    }
  }
  else if (key == ' ')
  {
    event = new Event(EventType.SPACEBAR_PRESSED);
    eventManager.queueEvent(event);
    return;
  }
}

void keyReleased()
{
  Event event;
  
  if (key == CODED)
  {
    switch (keyCode)
    {
      case UP:
        event = new Event(EventType.UP_BUTTON_RELEASED);
        eventManager.queueEvent(event);
        return;
        
      case LEFT:
        event = new Event(EventType.LEFT_BUTTON_RELEASED);
        eventManager.queueEvent(event);
        return;
        
      case RIGHT:
        event = new Event(EventType.RIGHT_BUTTON_RELEASED);
        eventManager.queueEvent(event);
        return;
    }
  }
}

void mouseClicked()
{
  Event event = new Event(EventType.MOUSE_CLICKED);
  event.addIntParameter("mouseX", mouseX);
  event.addIntParameter("mouseY", mouseY);
  eventManager.queueEvent(event);
  return;
}

void myoOnEmg(Myo myo, long nowMilliseconds, int[] sensorData) {
  emgManager.onEmg(nowMilliseconds, sensorData);
}

class FalldownContactListener implements ContactListener
{
  @Override public void beginContact(Contact contact)
  {
    IGameObject objectA = (IGameObject)contact.getFixtureA().getUserData();
    IGameObject objectB = (IGameObject)contact.getFixtureB().getUserData();
    
    RigidBodyComponent rigidBodyA = (RigidBodyComponent)objectA.getComponent(ComponentType.RIGID_BODY);
    RigidBodyComponent rigidBodyB = (RigidBodyComponent)objectB.getComponent(ComponentType.RIGID_BODY);
    
    rigidBodyA.onCollisionEnter(objectB);
    rigidBodyB.onCollisionEnter(objectA);
  }
  
  @Override public void endContact(Contact contact)
  {
  }
  
  @Override public void preSolve(Contact contact, Manifold oldManifold)
  {
  }
  
  @Override public void postSolve(Contact contact, ContactImpulse impulse)
  {
  }
}