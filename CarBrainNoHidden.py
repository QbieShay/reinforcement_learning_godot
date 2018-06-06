import tensorflow as tf

from godot import exposed, export
from godot.bindings import *



@exposed
class CarBrainNoHidden(Node):

	def _ready(self):
		self.input_params = tf.placeholder(tf.float32, [1, 10])
		self.output = tf.layers.dense(inputs=self.input_params, units=6)
		self.actual_v = tf.placeholder ( tf.float32, [1,6])
		self.loss = tf.losses.mean_squared_error(self.actual_v,self.output)
		self.optimizer = tf.train.GradientDescentOptimizer(0.2)
		self.train = self.optimizer.minimize(self.loss)
		self.g_output = tf.gather(self.output, 0)
		self.session = tf.Session()
		self.session.run(tf.global_variables_initializer())
		print("Tf initialized")
	
	def get_prediction(self, g_params, who):
		print("predicting")
		ret = self.session.run(self.g_output, feed_dict = {self.input_params : [g_params]})
		print(ret)
		####not working#####
		self.a = "what is happening" #+ ret[0]
		#who.prediction = a
		#####working#####
		#who.prediction = wtf
	
	def train(self, real_values):
		self.session.run(self.train, feed_dict = {self.actual_v: [real_values]})

